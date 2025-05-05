defmodule QuizaarWeb.Router do
  use QuizaarWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/api", QuizaarWeb do
    pipe_through :api

    get "/", DefaultController, :index
    post "/accounts/create", AccountController, :create
  end
end
