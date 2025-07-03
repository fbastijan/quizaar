defmodule QuizaarWeb.QuestionJSON do
  alias Quizaar.Quizzes.Question

  @doc """
  Renders a list of questions.
  """
  def index(assigns) do
    %{questions: Enum.map(assigns.questions, &data/1)}
  end

  def index2(%{questions: questions}) do
    %{data: for(question <- questions, do: data(question))}
  end

  @doc """
  Renders a single question.
  """
  def show(%{question: question}) do
    %{data: data(question)}
  end

  def data({:ok, %Quizaar.Quizzes.Question{} = question}), do: data(question)

  def data(%Quizaar.Quizzes.Question{} = question) do
    %{
      id: question.id,
      text: question.text,
      answer: question.answer,
      options: question.options,
      used: question.used,
      quiz_id: question.quiz_id,
      inserted_at: question.inserted_at,
      updated_at: question.updated_at
    }
  end
end
