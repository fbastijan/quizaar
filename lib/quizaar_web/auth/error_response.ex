defmodule QuizaarWeb.Auth.ErrorResponse.Unauthorized do
  defexception message: "Unauthorized", plug_status: 401
end

defmodule QuizaarWeb.Auth.ErrorResponse.Forbidden do
  defexception message: "You dont have acess to this resource", plug_status: 403
end

defmodule QuizaarWeb.Auth.ErrorResponse.NotFound do
  defexception message: "Not found", plug_status: 404
end
