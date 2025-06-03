defmodule QuizaarWeb.QuizChannel do
  use QuizaarWeb, :channel
  alias QuizaarWeb.Auth.Guardian
  alias Quizaar.Accounts
  alias Quizaar.Quizzes
  alias Quizaar.Players
  alias QuizaarWeb.Presence

  alias QuizaarWeb.QuestionJSON
  @impl true

  def join("quiz:" <> join_code, params, socket) do
    quiz = Quizzes.get_quiz_by_code!(join_code)

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
              session_id -> session_id
            end

          player = Players.get_player_by_session_id(session_id)

          socket
          |> assign(:guest, true)
          |> assign(:session_id, session_id)
          |> assign(:role, "player")
          |> assign(:name, Map.get(params, "name"))
          |> assign(:player, player)

        token ->
          case authorized(token, socket) do
            {:ok, socket} ->
              role = if socket.assigns.account.user.id == quiz.user_id, do: "organizer"

              player = Players.get_player_by_user(socket.assigns.account.user.id)
              IO.inspect(quiz.id, label: "Quiz ID")
              IO.inspect(socket.assigns.account.user.id, label: "User ID")

              socket
              |> assign(:role, role)
              |> assign(:player, player)
              |> assign(:quiz_id, quiz.id)

            {:error, reason} ->
              IO.inspect("Unauthorized access attempt with token: #{reason}")
              socket
          end
      end

    send(self(), :after_join)
    IO.inspect(socket.assigns)
    {:ok, socket}
  end

  def can_add_player?(quiz_id, max_players \\ 10) do
    count = Players.count_players_for_quiz(quiz_id)
    count < max_players
  end

  @impl true
  def handle_info(:after_join, socket) do
    join_code = socket.assigns.join_code
    quiz = socket.assigns.quiz

    socket =
      case Quizzes.get_question!(quiz.current_question_id) do
        nil -> socket
        question -> assign(socket, :current_question, question)
      end

    IO.inspect(socket.assigns, label: "Socket Assigns After Join")

    cond do
      account = socket.assigns[:account] ->
        handle_registered_player(socket, quiz, account)

      true ->
        handle_guest_player(socket, quiz)
    end
  end

  defp handle_registered_player(socket, quiz, account) do
    player_params = %{
      session_id: nil,
      name: account.user.full_name,
      user_id: account.user.id,
      quiz_id: quiz.id
    }

    IO.inspect(player_params, label: "Player Params")
    handle_player_creation(socket, quiz, player_params, account.id, account.user.full_name)
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

    handle_player_creation(socket, quiz, player_params, session_id, guest_name)
  end

  defp handle_player_creation(socket, quiz, player_params, presence_key, user_name) do
    if can_add_player?(quiz.id, 10) do
      case Players.create_player(player_params) do
        {:ok, player} ->
          {:ok, _} =
            Presence.track(socket, presence_key, %{
              online_at: inspect(System.system_time(:second)),
              user_name: user_name
            })

          socket = assign(socket, :player, player)
          push(socket, "presence_state", Presence.list(socket))
          {:noreply, socket}

        {:error, changeset} ->
          push(socket, "error", %{message: "Failed to create player", details: inspect(changeset)})

          {:noreply, socket}
      end
    else
      socket = assign(socket, :role, "spectator")
      push(socket, "info", %{message: "Max players reached, you are a spectator"})
      {:noreply, socket}
    end
  end

  @impl true
  def handle_in("generate_questions", payload, socket) do
    if socket.assigns.role == "organizer" do
      quiz_id = socket.assigns.quiz_id

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
          {:noreply, socket}

        {:error, reason} ->
          # Handle the error response
          push(socket, "error", %{message: reason})
          {:noreply, socket}
      end
    else
      push(socket, "error", %{message: "You are not authorized to generate questions"})
      {:noreply, socket}
    end
  end

  def handle_in("answer_question", payload, socket) do
    answered =
      Quizzes.check_if_answered(socket.assigns.player.id, socket.assigns.current_question.id)

    if socket.assigns.player != nil and !answered do
      question = socket.assigns.current_question
      player = socket.assigns.player
      quiz = socket.assigns.quiz
      answer = payload["answer"]

      case Quizzes.verify_choice(question, quiz, player.id, answer) do
        {:ok, %{result: result, answer: answer}} ->
          # Handle the successful response
          push(socket, "answer_result", %{result: result.id, answer: answer.id})
          {:noreply, socket}

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

  def handle_in("serve_question", _payload, socket) do
    if socket.assigns.role == "organizer" do
      case Quizzes.serve_question(socket.assigns.quiz) do
        {:ok, question} ->
          # Handle the successful response
          socket = assign(socket, :current_question, question)

          broadcast!(socket, "question_served", %{
            question: QuestionJSON.show(%{question: question})
          })

          {:noreply, socket}

        {:error, :end, _reason} ->
          # Handle the end of the quiz
          broadcast!(socket, "quiz_ended", %{message: "Quiz has ended"})
          {:noreply, socket}

        {:error, reason} ->
          # Handle the error response
          push(socket, "error", %{message: reason})
          {:noreply, socket}
      end
    else
      push(socket, "error", %{message: "You are not authorized to serve questions"})
      {:noreply, socket}
    end
  end

  @impl true

  def handle_in("delete_player", payload, socket) do
    if socket.assigns.role == "organizer" do
      player_id = payload["player_id"]

      case Players.get_player!(player_id) do
        nil ->
          # Handle the error response
          push(socket, "error", %{message: "Player not found"})
          {:noreply, socket}

        player ->
          Players.delete_player(player)
          push(socket, "player_deleted", %{message: "Player deleted successfully"})
          {:noreply, socket}
      end
    else
      push(socket, "error", %{message: "You are not authorized to delete players"})
      {:noreply, socket}
    end
  end

  # @imp true
  # def handle_in("add_player", payload, socket) do
  #   IO.inspect(socket)
  #   if socket.assigns.role == "organizer" do
  #     quiz_id = socket.assigns.quiz_id
  #     user_id = payload["user_id"]
  #     case Players.create_player(%{quiz_id, user_id})do
  #      {:ok, player} ->
  #         # Handle the successful response
  #         push(socket, "player_added", %{player: player})
  #         {:noreply, socket}
  #       {:error, reason} ->
  #         # Handle the error response
  #         push(socket, "error", %{message: reason})
  #         {:noreply, socket}
  #     end
  #   else
  #     push(socket, "error", %{message: "You are not authorized to add players"})
  #       {:noreply, socket}
  #   end
  #  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (quiz:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
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
end
