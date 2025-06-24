defmodule Quizaar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    unless Mix.env() == :prod do
      Dotenv.load()
      Mix.Task.run("loadconfig")
    end

    children = [
      QuizaarWeb.Telemetry,
      Quizaar.Repo,
      {DNSCluster, query: Application.get_env(:quizaar, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Quizaar.PubSub},
      QuizaarWeb.Presence,
      # Start a worker by calling: Quizaar.Worker.start_link(arg)
      # {Quizaar.Worker, arg},
      # Start to serve requests, typically the last entry
      QuizaarWeb.Endpoint,
      {Finch, name: Quizaar.Finch},
      {Registry, keys: :unique, name: Quizaar.TimerRegistry}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Quizaar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QuizaarWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
