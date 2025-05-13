defmodule QuizaarWeb.AnswerJSON do
  alias Quizaar.Quizzes.Answer

  @doc """
  Renders a list of answers.
  """
  def index(%{answers: answers}) do
    %{data: for(answer <- answers, do: data(answer))}
  end

  @doc """
  Renders a single answer.
  """
  def show(%{answer: answer}) do
    %{data: data(answer)}
  end

  defp data(%Answer{} = answer) do
    %{
      id: answer.id,
      text: answer.text,
      is_correct: answer.is_correct
    }
  end
end
