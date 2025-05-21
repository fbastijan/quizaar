defmodule QuizaarWeb.QuizChannel do
  use QuizaarWeb, :channel
  alias QuizaarWeb.Auth.Guardian
  alias Quizaar.Accounts
  alias Quizaar.Quizzes
  alias QuizaarWeb.Presence
  @impl true


  def join("quiz:" <> join_code, %{"token" => token}, socket) do
     socket = assign(socket, :join_code, join_code)
    send(self(), :after_join)
    case  authorized(token, socket) do

      {:ok, socket} ->
        IO.inspect(socket)
        # If the user is authorized, join the channel
        {:ok, socket}
      {:error, _reason} ->
        # If the user is not authorized, return an error
        {:error, %{reason: "unauthorized"}}
    end

  end
 @impl true
  def join("quiz:" <> _join_code, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

   @impl true
  def handle_info(:after_join, socket) do
    account_id = socket.assigns.account
    account = Accounts.get_full_account(account_id)
    socket = assign(socket, :account, account)
    join_code = socket.assigns.join_code

   socket = case Quizzes.get_quiz_by_code!(join_code) do
      nil ->
       socket

      quiz ->
        IO.inspect(account.user.id)
        IO.inspect(quiz)
        if quiz.user_id == account.user.id do
          socket
            |> assign(:quiz_id, quiz.id)
            |> assign(:role, "organizer")

        else
          socket
            |> assign(:quiz_id, quiz.id)
            |> assign(:role, "player")

        end
    end
    {:ok, _} =
      Presence.track(socket, account.user.id, %{
        online_at: inspect(System.system_time(:second)),
        user_name: account.user.full_name,
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
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
              {:ok, assign(socket, :account, account.id)}

        {:error, _reason} ->
          {:error, :unauthorized}


       end

  end
end
