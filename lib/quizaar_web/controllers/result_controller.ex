defmodule QuizaarWeb.ResultController do
  use QuizaarWeb, :controller

  alias Quizaar.Quizzes
  alias Quizaar.Quizzes.Result

  action_fallback QuizaarWeb.FallbackController

  def index(conn, _params) do
    results = Quizzes.list_results()
    render(conn, :index, results: results)
  end

  def create(conn, %{"result" => result_params}) do
    with {:ok, %Result{} = result} <- Quizzes.create_result(result_params) do
      conn
      |> put_status(:created)
      |> render(:show, result: result)
    end
  end

  def show(conn, %{"id" => id}) do
    result = Quizzes.get_result!(id)
    render(conn, :show, result: result)
  end

  def update(conn, %{"id" => id, "result" => result_params}) do
    result = Quizzes.get_result!(id)

    with {:ok, %Result{} = result} <- Quizzes.update_result(result, result_params) do
      render(conn, :show, result: result)
    end
  end

  def delete(conn, %{"id" => id}) do
    result = Quizzes.get_result!(id)

    with {:ok, %Result{}} <- Quizzes.delete_result(result) do
      send_resp(conn, :no_content, "")
    end
  end
end
