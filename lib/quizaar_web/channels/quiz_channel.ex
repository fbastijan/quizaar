defmodule QuizaarWeb.QuizChannel do
  use QuizaarWeb, :channel
  alias QuizaarWeb.Auth.Guardian
  alias Quizaar.Accounts
  alias Quizaar.Quizzes
  alias Quizaar.Players
  alias QuizaarWeb.Presence
  alias Quizaar.Quizzes.Question
  alias QuizaarWeb.QuestionJSON

  @impl true

  def join("quiz:" <> join_code, params, socket) do
    quiz = Quizzes.get_quiz_by_code(join_code)

    if quiz == nil do
      {:error, %{reason: "Quiz not found"}}
    else
      socket =
        socket
        |> assign(:join_code, join_code)
        |> assign(:quiz, quiz)

      socket =
        case Map.get(params, "token") do
          nil ->
            # Guest: assign a session_id and guest role
            session_id =
              case Map.get(params, "session_id") do
                nil -> Ecto.UUID.generate()
                "" -> Ecto.UUID.generate()
                session_id -> session_id
              end

            player = Players.get_player_by_session_id_and_quiz(session_id, quiz.id)

            socket
            |> assign(:guest, true)
            |> assign(:session_id, session_id)
            |> assign(:role, "player")
            |> assign(:name, Map.get(params, "name"))
            |> assign(:player, player)

          token ->
            case authorized(token, socket) do
              {:ok, socket} ->
                role =
                  if socket.assigns.account.user.id == quiz.user_id,
                    do: "organizer",
                    else: "player"

                player =
                  Players.get_player_by_user_and_quiz(socket.assigns.account.user.id, quiz.id)

                socket
                |> assign(:role, role)
                |> assign(:player, player)

              {:error, _reason} ->
                socket
            end
        end

      send(self(), :after_join)

      {:ok, socket}
    end
  end

  def can_add_player?(quiz_id, max_players \\ 10) do
    count = Players.count_players_for_quiz(quiz_id)
    count < max_players
  end

  defp question_expired?(quiz) do
    if(quiz.current_question_id != nil) do
      current_time = DateTime.utc_now()

      question_end_time =
        DateTime.add(quiz.question_started_at, quiz.question_time_limit, :second)

      DateTime.compare(current_time, question_end_time) == :gt
    else
      false
    end
  end

  @impl true
  def handle_info(:close_question, socket) do
    broadcast!(socket, "question_closed", %{message: "Time is up! No more answers allowed."})
    # Optionally, update socket assigns or state to disallow further answers
    {:noreply, assign(socket, :question_closed, true)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    quiz = socket.assigns.quiz

    socket =
      if question_expired?(quiz) do
        socket = assign(socket, :question_closed, true)
        push(socket, "question_closed", %{message: "Time is up! No more answers allowed."})
        socket
      else
        assign(socket, :question_closed, false)
      end

    socket =
      case quiz.current_question_id do
        nil ->
          socket

        question_id ->
          case Quizzes.get_question(question_id) do
            nil ->
              socket

            question ->
              player = socket.assigns[:player]

              answered =
                if player do
                  Quizzes.check_if_answered(socket.assigns.player.id, question.id) || false
                end

              if answered do
                push(socket, "question_closed", %{
                  message: "You have already answered this question."
                })
              end

              assign(socket, :current_question, question)
          end
      end

    if question = socket.assigns[:current_question] do
      push(socket, "active_question", %{
        question: QuestionJSON.show(%{question: question}),
        time_left: time_left(quiz)
      })
    end

    if socket.assigns.role == "player" do
      cond do
        account = socket.assigns[:account] ->
          handle_registered_player(socket, quiz, account)

        true ->
          handle_guest_player(socket, quiz)
      end
    else
      # If the user is not a player, just assign the quiz and role
      push(socket, "presence_state", Presence.list(socket))
      {:noreply, socket}
    end
  end

  defp handle_registered_player(socket, quiz, account) do
    player_params = %{
      session_id: nil,
      name: account.user.full_name,
      user_id: account.user.id,
      quiz_id: quiz.id
    }

    handle_player_creation(socket, quiz, player_params, account.user.id, account.user.full_name)
  end

  defp handle_guest_player(socket, quiz) do
    session_id = socket.assigns[:session_id] || Ecto.UUID.generate()

    guest_name = socket.assigns[:name] || "Guest Player"

    player_params = %{
      session_id: session_id,
      name: guest_name,
      quiz_id: quiz.id,
      user_id: nil
    }

    push(socket, "guest_joined", %{session_id: session_id, name: guest_name})

    handle_player_creation(socket, quiz, player_params, session_id, guest_name)
  end

  defp handle_player_creation(socket, quiz, player_params, presence_key, user_name) do
    {:ok, _} =
      Presence.track(socket, presence_key, %{
        online_at: inspect(System.system_time(:second)),
        user_name: user_name,
        role: socket.assigns.role,
        ready: false
      })

    push(socket, "presence_state", Presence.list(socket))

    if can_add_player?(quiz.id, 50) do
      case Players.create_player(player_params) do
        {:ok, player} ->
          socket = assign(socket, :player, player)

          broadcast!(socket, "player_created", %{
            player: %{
              id: player.id,
              name: player.name,
              session_id: player.session_id,
              user_id: player.user_id
            }
          })

          {:noreply, socket}

        {:error, changeset} ->
          push(socket, "error", %{message: "Failed to create player", details: inspect(changeset)})

          {:noreply, socket}
      end
    else
      socket = assign(socket, :role, "spectator")
      Presence.update(socket, presence_key, %{role: "spectator"})
      push(socket, "info", %{message: "Max players reached, you are a spectator"})
      {:noreply, socket}
    end
  end

  @impl true
  def handle_in("get_players", payload, socket) do
    if socket.assigns.role == "organizer" || socket.assigns.role == "player" do
      quiz_id = socket.assigns.quiz.id || payload["quiz_id"]
      players = Players.get_players_by_quiz(quiz_id)

      player_list =
        Enum.map(players, fn player ->
          %{
            id: player.id,
            name: player.name,
            session_id: player.session_id,
            user_id: player.user_id
          }
        end)

      push(socket, "players_list", %{players: player_list})
      {:reply, {:ok, %{players: player_list}}, socket}
    else
      {:reply, {:error, %{message: "You are not authorized to get players"}}, socket}
    end
  end

  @impl true
  def handle_in("generate_questions", payload, socket) do
    if socket.assigns.role == "organizer" do
      quiz_id = socket.assigns.quiz.id

      config = %{
        number: payload["number"],
        topic: payload["topic"],
        description: payload["description"],
        difficulty: payload["difficulty"]
      }

      case Quizzes.create_questions(quiz_id, config) do
        {:ok, _questions} ->
          # Handle the successful response
          push(socket, "questions_generated", %{questions: "questions"})
          {:reply, {:ok, %{"message" => "Questions generated successfully"}}, socket}

        {:error, reason} ->
          # Handle the error response

          {:reply, {:error, reason}, socket}
      end
    else
      {:reply, {:error, %{message: "You are not authorized to generate questions"}}, socket}
    end
  end

  def handle_in("get_current_question", _payload, socket) do
    current_question = socket.assigns.current_question
    quiz = socket.assigns.quiz

    {:reply,
     {:ok,
      %{question: QuestionJSON.show(%{question: current_question}), time_left: time_left(quiz)}},
     socket}
  end

  @impl true
  def handle_in("answer_question", payload, socket) do
    if socket.assigns.role != "player" do
      push(socket, "error", %{message: "Only players can answer questions"})
      {:reply, {:error, "Only players can answer questions"}, socket}
    else
      changeset = Question.changeset(%Quizzes.Question{}, payload["question"])

      question =
        if changeset.valid? do
          Ecto.Changeset.apply_changes(changeset)
        else
          nil
        end

      player = socket.assigns.player
      expired = socket.assigns[:question_closed] || false

      answered =
        Quizzes.check_if_answered(player.id, question.id)

      if player != nil and not answered and not expired do
        quiz = Quizzes.get_quiz!(socket.assigns.quiz.id)
        answer = payload["answer"]

        case Quizzes.answer_and_score(question, quiz, player.id, answer) do
          {:ok, %{result: result, answer: answer}} ->
            # Handle the successful response

            broadcast!(socket, "answer_received", %{})
            {:reply, {:ok, %{result: result.score, answer: answer.id}}, socket}

          _ ->
            # Handle the error response
            push(socket, "error", %{message: "Error verifying answer"})
            {:noreply, socket}
        end
      else
        push(socket, "error", %{message: "already answered"})
        {:noreply, socket}
      end
    end
  end

  def handle_in("fix_answer", payload, socket) do
    if socket.assigns.role == "organizer" do
      answer = payload["answer"]
      quiz = socket.assigns.quiz

      if answer do
        case Quizzes.fix_answer_scoring(quiz, answer) do
          {:ok, %{answer: fixed_answer, result: _result}} ->
            broadcast!(socket, "answer_received", %{fixed: true})

            {:reply, {:ok, %{answer: QuizaarWeb.AnswerJSON.show(%{answer: fixed_answer})}},
             socket}

          {:error, failed_operation, failed_value, _changes_so_far} ->
            {:reply,
             {:error,
              %{
                failed_operation: failed_operation,
                failed_value: failed_value,
                message: "Failed updating score"
              }}, socket}
        end
      else
        {:reply, {:error, %{message: "No answer found"}}, socket}
      end
    else
      {:reply, {:error, %{message: "You are not authorized"}}, socket}
    end
  end

  def handle_in("get_all_answers_to_current", _payload, socket) do
    current_question = socket.assigns.current_question
    quiz = socket.assigns.quiz

    if current_question == nil do
      push(socket, "error", %{message: "No current question"})
      {:reply, {:error, "No current question"}, socket}
    end

    answers = Quizzes.get_all_answers_to_current(current_question.id)

    {:reply,
     {:ok,
      %{
        quiz: %{
          id: quiz.id,
          title: quiz.title,
          description: quiz.description,
          join_code: quiz.join_code
        },
        current_question: QuestionJSON.show(%{question: current_question}),
        answers: QuizaarWeb.AnswerJSON.index(%{answers: answers})
      }}, socket}
  end

  def handle_in("players_stats", _payload, socket) do
    if socket.assigns.role == "organizer" || socket.assigns.role == "player" do
      quiz_id = socket.assigns.quiz.id
      players = Players.get_players_by_quiz(quiz_id)

      player_stats =
        Enum.map(players, fn player ->
          %{
            id: player.id,
            name: player.name,
            session_id: player.session_id,
            user_id: player.user_id,
            score: Quizzes.get_player_score(player.id)
          }
        end)

      {:reply, {:ok, %{players: player_stats}}, socket}
    else
      {:reply, {:error, %{message: "You are not authorized to get player stats"}}, socket}
    end
  end

  def handle_in("player_stats", _payload, socket) do
    if socket.assigns.role == "organizer" || socket.assigns.role == "player" do
      player = socket.assigns.player
      quiz = socket.assigns.quiz

      if player do
        score = Quizzes.get_player_score_with_neighbours(player.id, quiz.id) || 0
        IO.inspect(score, label: "Player in player_stats")

        {:reply,
         {:ok,
          %{
            higher_player: %{
              name: score.higher_player.name || nil,
              score: score.higher_player.score || nil
            },
            player: %{
              name: score.player.name,
              score: score.player.score,
              placement: score.player.placement || 0
            },
            lower_player: %{
              name: score.lower_player.name || nil,
              score: score.lower_player.score || nil
            }
          }}, socket}
      else
        push(socket, "error", %{message: "Player not found"})
        {:noreply, socket}
      end
    else
      push(socket, "error", %{message: "You are not authorized to get player stats"})
      {:noreply, socket}
    end
  end

  def handle_in("serve_question", _payload, socket) do
    if socket.assigns.role == "organizer" do
      quiz = socket.assigns.quiz

      case Quizzes.serve_question(quiz) do
        {:ok, question, quiz} ->
          # Handle the successful response
          socket =
            socket
            |> assign(:current_question, question)
            |> assign(:quiz, quiz)

          broadcast!(socket, "question_served", %{
            question: QuestionJSON.show(%{question: question}),
            time_left: time_left(quiz)
          })

          Quizaar.QuizTimer.start_timer(quiz.join_code, quiz.question_time_limit, self())

          {:reply,
           {:ok,
            %{
              question: QuestionJSON.show(%{question: question}),
              time_left: time_left(quiz)
            }}, socket}

        {:error, :end, reason} ->
          broadcast!(socket, "quiz_ended", %{message: "Quiz has ended"})
          {:reply, {:error, reason}, socket}

        {:error, reason} ->
          {:reply, {:error, reason}, socket}
      end
    else
      {:reply, {:error, %{message: "You are not authorized to serve questions"}}, socket}
    end
  end

  def handle_in("ready_up", _payload, socket) do
    if socket.assigns.role == "player" do
      presence_key =
        cond do
          Map.has_key?(socket.assigns, :session_id) -> socket.assigns.session_id
          Map.has_key?(socket.assigns, :account) -> socket.assigns.account.user.id
          true -> nil
        end

      Presence.update(socket, presence_key, %{ready: true})
      push(socket, "presence_update", Presence.list(socket))
      {:reply, {:ok, %{"message" => "You are ready"}}, socket}
    else
      {:reply, {:error, %{message: "Only players can ready up"}}, socket}
    end
  end

  @impl true
  def handle_in("unready", _payload, socket) do
    if socket.assigns.role == "organizer" || "player" do
      presence_key =
        cond do
          Map.has_key?(socket.assigns, :session_id) -> socket.assigns.session_id
          Map.has_key?(socket.assigns, :account) -> socket.assigns.account.id
          true -> nil
        end

      Presence.update(socket, presence_key, %{ready: false})
      push(socket, "presence_update", Presence.list(socket))
      {:reply, {:ok, %{"message" => "You are no longer ready"}}, socket}
    else
      {:reply, {:error, %{message: "Only players can unready"}}, socket}
    end
  end

  def handle_in("quiz_start", _payload, socket) do
    if socket.assigns.role == "organizer" do
      case check_if_all_players_ready(socket) do
        {:ok, socket} ->
          broadcast!(socket, "quiz_start", %{message: "Quiz is starting!"})
          handle_in("serve_question", %{}, socket)

        {:error, :not_ready} ->
          {:reply, {:error, %{message: "Not all players are ready"}}, socket}
      end
    else
      {:reply, {:error, %{message: "You are not authorized to start the quiz"}}, socket}
    end
  end

  @impl true

  def handle_in("delete_player", payload, socket) do
    if socket.assigns.role == "organizer" do
      player_id = payload["player_id"]

      case Players.get_player(player_id) do
        nil ->
          # Handle the error response

          {:reply, {:error, %{message: "Player not found to delete"}}, socket}

        player ->
          {:ok, player} = Players.delete_player(player)

          player_ref = %{
            id: player.id,
            name: player.name,
            session_id: player.session_id,
            user_id: player.user_id
          }

          {:reply, {:ok, %{player: player_ref}}, socket}
      end
    else
      {:reply, {:error, %{message: "You are not authorized to delete players"}}, socket}
    end
  end

  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  defp authorized(token, socket) do
    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        {:ok, account} = Guardian.resource_from_claims(claims)
        account = Accounts.get_full_account(account.id)
        {:ok, assign(socket, :account, account)}

      {:error, _reason} ->
        {:error, :unauthorized}
    end
  end

  defp all_players_ready?(socket) do
    players = Presence.list(socket)

    Enum.all?(players, fn
      {_key, %{metas: metas}} ->
        Enum.any?(metas, fn meta -> meta[:ready] == true end)
    end)
  end

  defp all_players_present?(socket, quiz_id) do
    players_present = Presence.list(socket)
    players = Players.get_players_by_quiz(quiz_id)

    Enum.all?(players, fn player ->
      Map.has_key?(players_present, player.session_id) ||
        Map.has_key?(players_present, player.user_id)
    end)
  end

  defp check_if_all_players_ready(socket) do
    quiz_id = socket.assigns.quiz.id

    if all_players_ready?(socket) and all_players_present?(socket, quiz_id) do
      broadcast!(socket, "all_players_ready", %{message: "All players are ready!"})
      {:ok, socket}
    else
      {:error, :not_ready}
    end
  end

  defp time_left(quiz) do
    if quiz.current_question_id && quiz.question_started_at && quiz.question_time_limit do
      now = DateTime.utc_now()
      end_time = DateTime.add(quiz.question_started_at, quiz.question_time_limit, :second)
      time_left = DateTime.diff(end_time, now, :second)
      if time_left < 0, do: 0, else: time_left
    else
      0
    end
  end
end
