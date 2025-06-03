defmodule QuizaarWeb.QuizController do
  use QuizaarWeb, :controller

  alias Quizaar.Quizzes
  alias Quizaar.Quizzes.Quiz

  action_fallback QuizaarWeb.FallbackController
  import QuizaarWeb.Auth.AuthorizedPlug
  plug :is_authorized when action in [:create, :update, :delete]

  def index(conn, _params) do
    quizzes = Quizzes.list_quizzes()
    render(conn, :index, quizzes: quizzes)
  end

  def create(conn, %{"quiz" => quiz_params}) do
    with {:ok, %Quiz{} = quiz} <- Quizzes.create_quiz(quiz_params) do
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

  def delete(conn, %{"id" => id}) do
    quiz = Quizzes.get_quiz!(id)

    with {:ok, %Quiz{}} <- Quizzes.delete_quiz(quiz) do
      send_resp(conn, :no_content, "")
    end
  end
end
