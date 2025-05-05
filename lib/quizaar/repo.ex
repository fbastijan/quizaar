defmodule Quizaar.Repo do
  use Ecto.Repo,
    otp_app: :quizaar,
    adapter: Ecto.Adapters.Postgres
end
