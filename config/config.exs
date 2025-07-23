# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :quizaar,
  ecto_repos: [Quizaar.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :quizaar, QuizaarWeb.Endpoint,
  url: [host: "localhost"],
  check_origin: ["//localhost:5173", "http://116.203.210.54:8081"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: QuizaarWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Quizaar.PubSub,
  live_view: [signing_salt: "55rTK2cA"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :quizaar, QuizaarWeb.Auth.Guardian,
  issuer: "quizaar",
  secret_key: System.get_env("GUARDIAN_KEY") || "dctGkjgl2FJfPfXs11ycHSgQzpiujGV8mMKBPKv9pBxy31eNCGCiqd/LlTH36R45"

config :guardian, Guardian.DB,
  repo: Quizaar.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 60

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
