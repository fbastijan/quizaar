defmodule QuizaarWeb.QuizChannel do
  use QuizaarWeb, :channel
  alias QuizaarWeb.Auth.Guardian
  @impl true


  def join("quiz:" <> join_code, %{"token" => token}, socket) do

    case  authorized(token, socket) do

      {:ok, socket} ->
        # If the user is authorized, join the channel
        {:ok, socket}
      {:error, _reason} ->
        # If the user is not authorized, return an error
        {:error, %{reason: "unauthorized"}}
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
