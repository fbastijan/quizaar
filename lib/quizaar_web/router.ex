defmodule QuizaarWeb.Router do
  use QuizaarWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", QuizaarWeb do
    pipe_through :api
    get "/", DefaultController, :index
  end
end
