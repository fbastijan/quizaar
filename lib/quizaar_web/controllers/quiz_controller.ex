defmodule QuizaarWeb.QuizController do
  use QuizaarWeb, :controller

  alias Quizaar.Quizzes
  alias Quizaar.Quizzes.Quiz

  action_fallback QuizaarWeb.FallbackController
  import QuizaarWeb.Auth.AuthorizedPlug
  plug :is_authorized when action in [:update, :delete]

  def index(conn, _params) do
    quizzes = Quizzes.list_quizzes()
    render(conn, :index, quizzes: quizzes)
  end

  def create(conn, %{"quiz" => quiz_params}) do
    updated_params =
      quiz_params
      |> Map.put("user_id", conn.assigns.account.user.id)

    with {:ok, %Quiz{} = quiz} <- Quizzes.create_quiz(updated_params) do
      conn
      |> put_status(:created)
      |> render(:show, quiz: quiz)
    end
  end

  def show(conn, %{"id" => id}) do
    quiz = Quizzes.get_quiz!(id)
    render(conn, :show, quiz: quiz)
  end

  def update(conn, %{"id" => id, "quiz" => quiz_params}) do
    quiz = Quizzes.get_quiz!(id)

    with {:ok, %Quiz{} = quiz} <- Quizzes.update_quiz(quiz, quiz_params) do
      render(conn, :show, quiz: quiz)
    end
  end

  def get_quiz_and_questions_by_join_code(conn, %{"join_code" => join_code}) do
    with quiz <- Quizzes.get_quiz_by_code(join_code),
         questions <- Quizzes.get_questions_by_quiz_id(quiz.id) do
      render(conn, :show_full_quiz, quiz: quiz, questions: questions)
    end
  end

  def list_quizzes_by_user(conn, _params) do
    user_id = conn.assigns.account.user.id
    quizzes = Quizzes.list_quizzes_by_user(user_id)
    render(conn, :index, quizzes: quizzes)
  end

  def delete(conn, %{"id" => id}) do
    quiz = Quizzes.get_quiz!(id)

    with {:ok, %Quiz{}} <- Quizzes.delete_quiz(quiz) do
      send_resp(conn, :no_content, "")
    end
  end
end
