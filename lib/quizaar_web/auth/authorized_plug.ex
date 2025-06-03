defmodule QuizaarWeb.Auth.AuthorizedPlug do
  alias QuizaarWeb.Auth.ErrorResponse

  def is_authorized(%{params: %{"account" => params}} = conn, _opts) do
    if conn.assigns.account.id == params["id"] do
      conn
    else
      raise ErrorResponse.Forbidden
    end
  end

  def is_authorized(%{params: %{"user" => params}} = conn, _opts) do
    if conn.assigns.account.user.id == params["id"] do
      conn
    else
      raise ErrorResponse.Forbidden
    end
  end

  def is_authorized(%{params: %{"quiz" => params}} = conn, _opts) do
    if conn.assigns.account.user.id == params["user_id"] do
      conn
    else
      raise ErrorResponse.Forbidden
    end
  end
end
