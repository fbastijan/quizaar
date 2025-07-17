defmodule QuizaarWeb.Router do
  use QuizaarWeb, :router
  use Plug.ErrorHandler

  defp handle_errors(conn, %{reason: %Phoenix.Router.NoRouteError{message: message}}) do
    conn |> json(%{errors: message}) |> halt()
  end

  defp handle_errors(conn, %{reason: %{message: message}}) do
    conn |> json(%{errors: message}) |> halt()
  end

  defp handle_errors(conn, %{
         reason: %QuizaarWeb.Auth.ErrorResponse.Unauthorized{message: message}
       }) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: message})
    |> halt()
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :auth do
    plug QuizaarWeb.Auth.Pipeline
    plug QuizaarWeb.Auth.SetAccount
  end

  scope "/api", QuizaarWeb do
    pipe_through :api

    get "/", DefaultController, :index
    post "/accounts/create", AccountController, :create
    post "/accounts/sign_in", AccountController, :sign_in
  end

  scope "/api", QuizaarWeb do
    pipe_through [:api, :auth]
    get "/accounts/current", AccountController, :current_account
    get "/accounts/by_id/:id", AccountController, :show
    patch "/accounts/update", AccountController, :update
    patch "/users/update", UserController, :update
    post "/accounts/refresh_session", AccountController, :refresh_session
    post "/quizzes/create", QuizController, :create
    post "/quizzes/:quiz_id/generate_questions", QuestionController, :generate_questions
    get "/quizzes/:join_code", QuizController, :get_quiz_and_questions_by_join_code
    get "/quizzes/:quiz_id/questions", QuestionController, :get_questions
    patch "/questions/:id", QuestionController, :update
    post "/questions/create", QuestionController, :create
    delete "/questions/:id", QuestionController, :delete

    get "/quizzes/list/user", QuizController, :list_quizzes_by_user
  end
end
