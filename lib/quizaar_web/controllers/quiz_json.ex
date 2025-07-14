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
      user_id: quiz.user_id,
      current_question_id: quiz.current_question_id,
      inserted_at: quiz.inserted_at,
    }
  end

  def show_full_quiz(%{quiz: quiz, questions: questions}) do
    %{
      data: %{
        quiz: data(quiz),
        questions: QuizaarWeb.QuestionJSON.index2(%{questions: questions})
      }
    }
  end
end
