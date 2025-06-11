defmodule QuizaarWeb.QuestionController do
  use QuizaarWeb, :controller

  alias Quizaar.Quizzes
  alias Quizaar.Quizzes.Question

  action_fallback QuizaarWeb.FallbackController

  def index(conn, _params) do
    questions = Quizzes.list_questions()
    render(conn, :index, questions: questions)
  end


  def generate_questions(conn, %{"quiz_id" => quiz_id} = params) do


      config = Map.delete(params, "quiz_id")
    with {:ok, questions} <- Quizzes.create_questions(quiz_id, config) do
      conn
      |> put_status(:created)
      |>render( :index, questions: questions)
    end
  end
  def create(conn, %{"question" => question_params}) do
    with {:ok, %Question{} = question} <- Quizzes.create_question(question_params) do
      conn
      |> put_status(:created)
      |> render(:show, question: question)
    end
  end

  def show(conn, %{"id" => id}) do
    question = Quizzes.get_question!(id)
    render(conn, :show, question: question)
  end

  def update(conn, %{"id" => id, "question" => question_params}) do
    question = Quizzes.get_question!(id)

    with {:ok, %Question{} = question} <- Quizzes.update_question(question, question_params) do
      render(conn, :show, question: question)
    end
  end

  def delete(conn, %{"id" => id}) do
    question = Quizzes.get_question!(id)

    with {:ok, %Question{}} <- Quizzes.delete_question(question) do
      send_resp(conn, :no_content, "")
    end
  end
end
