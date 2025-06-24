defmodule QuizaarWeb.AnswerJSON do
  alias Quizaar.Quizzes.Answer

  @doc """
  Renders a list of answers.
  """
  def index(%{answers: answers}) do
    %{data: for(answer <- answers, do: data2(answer))}
  end

  @doc """
  Renders a single answer.
  """
  def show(%{answer: answer}) do
    %{data: data(answer)}
  end
  defp data2(%Answer{} = answer) do
    %{
      id: answer.id,
      text: answer.text,
      is_correct: answer.is_correct,
       player: %{
        id: answer.player.id,
        name: answer.player.name
        }
    }
  end


  defp data(%Answer{} = answer) do
    %{
      id: answer.id,
      text: answer.text,
      is_correct: answer.is_correct

    }
  end
end
