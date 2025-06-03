defmodule QuizaarWeb.AnswerController do
  use QuizaarWeb, :controller

  alias Quizaar.Quizzes
  alias Quizaar.Quizzes.Answer

  action_fallback QuizaarWeb.FallbackController

  def index(conn, _params) do
    answers = Quizzes.list_answers()
    render(conn, :index, answers: answers)
  end

  def create(conn, %{"answer" => answer_params}) do
    with {:ok, %Answer{} = answer} <- Quizzes.create_answer(answer_params) do
      conn
      |> put_status(:created)
      |> render(:show, answer: answer)
    end
  end

  def show(conn, %{"id" => id}) do
    answer = Quizzes.get_answer!(id)
    render(conn, :show, answer: answer)
  end

  def update(conn, %{"id" => id, "answer" => answer_params}) do
    answer = Quizzes.get_answer!(id)

    with {:ok, %Answer{} = answer} <- Quizzes.update_answer(answer, answer_params) do
      render(conn, :show, answer: answer)
    end
  end

  def delete(conn, %{"id" => id}) do
    answer = Quizzes.get_answer!(id)

    with {:ok, %Answer{}} <- Quizzes.delete_answer(answer) do
      send_resp(conn, :no_content, "")
    end
  end
end
