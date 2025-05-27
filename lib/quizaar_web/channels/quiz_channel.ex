defmodule QuizaarWeb.QuizChannel do
  use QuizaarWeb, :channel
  alias QuizaarWeb.Auth.Guardian
  alias Quizaar.Accounts
  alias Quizaar.Quizzes
  alias Quizaar.Players
  alias QuizaarWeb.Presence
  @impl true


  def join("quiz:" <> join_code, params, socket) do
     socket = assign(socket, :join_code, join_code)
    send(self(), :after_join)
   case Map.get(params, "token") do
    nil ->
      # Guest: assign a session_id and guest role
     session_id = case Map.get(params, "session_id") do
      nil -> Ecto.UUID.generate()
      session_id -> session_id
     end

      socket =
        socket
        |> assign(:guest, true)
        |> assign(:session_id, session_id)
        |> assign(:role, "guest_player")
        |> assign(:name, Map.get(params, "name"))
      {:ok, socket}

    token ->
      case authorized(token, socket) do
        {:ok, socket} ->
          {:ok, socket}
        {:error, _reason} ->
          {:error, %{reason: "unauthorized"}}
      end
  end
  end
 @impl true
  def join("quiz:" <> _join_code, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

    def can_add_player?(quiz_id, max_players \\ 10) do
    count = Players.count_players_for_quiz(quiz_id)
    count < max_players
  end
   @impl true
  def handle_info(:after_join, socket) do
    join_code = socket.assigns.join_code
     quiz = Quizzes.get_quiz_by_code!(join_code)



          cond do

            account = socket.assigns[:account] ->
              # If the user is logged in, assign the account and role
            role = if account.user.id == quiz.user_id, do: "organizer", else: "player"

            player_params = %{
              session_id: nil,
              name: account.user.full_name, # Use the user's full name
              user_id: account.user.id,
              quiz_id: quiz.id
            }
              if can_add_player?(quiz.id, 10) do
                IO.inspect("entering player creation")
            case Players.create_player(player_params)do
              {:ok, player} ->
                socket= socket
                  |> assign(:role, role)
                  |> assign(:quiz_id, quiz.id)

                # Track the presence of the user
                {:ok, _} =
                  Presence.track(socket, account.id, %{
                    online_at: inspect(System.system_time(:second)),
                    user_name: account.user.full_name,
                  })

                push(socket, "presence_state", Presence.list(socket))
                {:noreply, socket}

              {:error, changeset} ->
                socket= socket
                  |> assign(:role, role)
                  |> assign(:quiz_id, quiz.id)
                push(socket, "info", %{message: "Already created this player rejoin!", details: inspect(changeset.errors)})
                {:noreply, socket}
            end
              else
                role = if role == "player", do: "spectator", else: role
                socket= socket
                  |> assign(:role, role)
                  |> assign(:quiz_id, quiz.id)

                {:noreply, socket}
              end





            true ->


              session_id = socket.assigns[:session_id] || Ecto.UUID.generate()
              guest_name = socket.assigns[:name] || "Guest Player"

              player_params = %{
                session_id: session_id,
                name: guest_name,
                quiz_id: quiz.id,
                user_id: nil
              }

               if can_add_player?(quiz.id, 10) do
              case Players.create_player(player_params)do

                  {:ok, player} ->
                            socket
                        |> assign(:quiz_id, quiz.id)
                        |> assign(:player_id, player.id)
                        |> assign(:session_id, session_id)
                      {:ok, _} =
                        Presence.track(socket, session_id, %{
                          online_at: inspect(System.system_time(:second)),
                          user_name: guest_name
                        })

                      push(socket, "presence_state", Presence.list(socket))
                      {:noreply, socket}


                {:error, changeset} ->
                  push(socket, "error", %{message: "Failed to create player", details: inspect(changeset)})
                  {:noreply, socket}



                end
               else
                role = "spectator"
                socket
                  |> assign(:role, role)
                  |> assign(:quiz_id, quiz.id)
                  |> assign(:session_id, session_id)
                  |> assign(:player_id, nil)
                push(socket, "info", %{message: "Max players reached, you are a spectator"})
                {:noreply, socket}
               end
              end
    end



   @impl true
  def handle_in("generate_questions", payload, socket) do
    IO.inspect(socket)
    if socket.assigns.role == "organizer" do
      quiz_id = socket.assigns.quiz_id
      config = %{
        number: payload["number"],
        topic: payload["topic"],
        description: payload["description"],
        difficulty: payload["difficulty"],
      }
      IO.inspect(config)
      IO.inspect(quiz_id)
      case Quizzes.create_questions(quiz_id, config)do
       {:ok, questions} ->
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
  @impl true

  def handle_in("delete_player", payload, socket) do
    if socket.assigns.role == "organizer" do
      quiz_id = socket.assigns.quiz_id
      player_id = payload["player_id"]

      case Players.get_player!(player_id)do
     player ->
          Players.delete_player(player)
          push(socket, "player_deleted", %{message: "Player deleted successfully"})
          {:noreply, socket}
        nil ->
          # Handle the error response
          push(socket, "error", %{message: "Player not found"})
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
       case  Guardian.decode_and_verify(token)do
        {:ok, claims}->
          {:ok, account} = Guardian.resource_from_claims(claims)
             account = Accounts.get_full_account(account.id)
              {:ok, assign(socket, :account, account)}

        {:error, _reason} ->
          {:error, :unauthorized}


       end

  end
end
