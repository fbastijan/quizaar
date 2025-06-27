defmodule Quizaar.QuizTimer do
  use GenServer

  # Start a timer for a quiz
  def start_timer(join_code, time_limit, channel_pid) do
     stop_timer(join_code)
    GenServer.start(__MODULE__, {join_code, time_limit, channel_pid}, name: via_tuple(join_code))
  end

  defp via_tuple(join_code), do: {:via, Registry, {Quizaar.TimerRegistry, join_code}}

  def stop_timer(join_code) do
    case GenServer.whereis(via_tuple(join_code)) do
      nil -> :ok
      pid -> GenServer.stop(pid, :normal)
    end
  end

  @impl true
  def init({join_code, time_limit, channel_pid}) do
    Process.send_after(self(), :close_question, time_limit * 1000)
    {:ok, %{join_code: join_code, channel_pid: channel_pid}}
  end

  @impl true
  def handle_info(:close_question, state) do
    IO.puts("QuizTimer: Broadcasting question_closed for quiz #{state.join_code}")
    # Broadcast to all clients on the quiz topic
    QuizaarWeb.Endpoint.broadcast!("quiz:" <> state.join_code, "question_closed", %{message: "Time is up! No more answers allowed."})
    {:stop, :normal, state}
  end
end
