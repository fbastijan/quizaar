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
    get "/accounts/by_id/:id", AccountController, :show
    patch "/accounts/update", AccountController, :update

  end
end
