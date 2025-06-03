defmodule QuizaarWeb.QuizJSON do
  alias Quizaar.Quizzes.Quiz

  @doc """
  Renders a list of quizzes.
  """
  def index(%{quizzes: quizzes}) do
    %{data: for(quiz <- quizzes, do: data(quiz))}
  end

  @doc """
  Renders a single quiz.
  """
  def show(%{quiz: quiz}) do
    %{data: data(quiz)}
  end

  defp data(%Quiz{} = quiz) do
    %{
      id: quiz.id,
      title: quiz.title,
      description: quiz.description,
      join_code: quiz.join_code,
      user_id: quiz.user_id
    }
  end
end
