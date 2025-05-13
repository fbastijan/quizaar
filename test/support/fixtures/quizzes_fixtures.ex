defmodule Quizaar.QuizzesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Quizaar.Quizzes` context.
  """

  @doc """
  Generate a quiz.
  """
  def quiz_fixture(attrs \\ %{}) do
    {:ok, quiz} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> Quizaar.Quizzes.create_quiz()

    quiz
  end

  @doc """
  Generate a question.
  """
  def question_fixture(attrs \\ %{}) do
    {:ok, question} =
      attrs
      |> Enum.into(%{
        answer: "some answer",
        options: ["option1", "option2"],
        text: "some text"
      })
      |> Quizaar.Quizzes.create_question()

    question
  end

  @doc """
  Generate a answer.
  """
  def answer_fixture(attrs \\ %{}) do
    {:ok, answer} =
      attrs
      |> Enum.into(%{
        is_correct: true,
        text: "some text"
      })
      |> Quizaar.Quizzes.create_answer()

    answer
  end

  @doc """
  Generate a result.
  """
  def result_fixture(attrs \\ %{}) do
    {:ok, result} =
      attrs
      |> Enum.into(%{
        score: 42
      })
      |> Quizaar.Quizzes.create_result()

    result
  end
end
