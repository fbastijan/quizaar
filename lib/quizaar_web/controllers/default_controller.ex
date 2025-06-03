defmodule QuizaarWeb.DefaultController do
  use QuizaarWeb, :controller

  def index(conn, _params) do
    text(conn, "Hello, world!")
  end
end
