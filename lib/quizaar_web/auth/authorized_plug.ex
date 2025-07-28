defmodule QuizaarWeb.Auth.AuthorizedPlug do
  alias QuizaarWeb.Auth.ErrorResponse

  def is_authorized(%{params: %{"account" => params}} = conn, _opts) do
    if conn.assigns.account.id == params["id"] do
      conn
    else
      raise ErrorResponse.Forbidden
    end
  end

  def is_authorized(%{params: %{"user" => params}} = conn, _opts) do
    if conn.assigns.account.user.id == params["id"] do
      conn
    else
      raise ErrorResponse.Forbidden
    end
  end

  def is_authorized(%{params: %{"quiz" => params}} = conn, _opts) do
    if conn.assigns.account.user.id == params["user_id"] do
      conn
    else
      raise ErrorResponse.Forbidden
    end
  end

  def is_authorized(%{params: %{"quiz_id" => quiz_id}} = conn, _opts) do
    quiz = Quizaar.Quizzes.get_quiz!(quiz_id)

    if conn.assigns.account.user.id == quiz.user_id do
      conn
    else
      IO.inspect(quiz.user_id, label: "Unauthorized access to quiz")
      IO.inspect(conn.assigns.account.user.id, label: "Current user ID")
      raise QuizaarWeb.Auth.ErrorResponse.Forbidden
    end
  end

  def is_authorized(%{params: %{"id" => id, "question" => question_params}} = conn, _opts) do
    quiz = Quizaar.Quizzes.get_quiz!(question_params["quiz_id"])

    if conn.assigns.account.user.id == quiz.user_id do
      conn
    else
      IO.inspect(quiz.user_id, label: "Unauthorized access to quiz")
      IO.inspect(conn.assigns.account.user.id, label: "Current user ID")
      raise QuizaarWeb.Auth.ErrorResponse.Forbidden
    end
  end

  def is_authorized(%Plug.Conn{private: %{phoenix_action: :delete, phoenix_controller: QuizaarWeb.QuestionController}, params: %{"id" => id}} = conn, _opts) do
  # Your authorization logic for deleting a question goes here.
  # Example: Only allow if the user owns the quiz this question belongs to.
  question = Quizaar.Quizzes.get_question!(id)
  quiz = Quizaar.Quizzes.get_quiz!(question.quiz_id)

  if conn.assigns.account.user.id == quiz.user_id do
    conn
  else
    raise QuizaarWeb.Auth.ErrorResponse.Forbidden
  end
end
end
