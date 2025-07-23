defmodule QuizaarWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :quizaar,
    module: QuizaarWeb.Auth.Guardian,
    error_handler: QuizaarWeb.Auth.GuardianErrorHandler

  plug Guardian.Plug.VerifySession
  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
