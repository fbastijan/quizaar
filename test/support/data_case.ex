defmodule Quizaar.Support.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Ecto.Changeset
      import Quizaar.Support.DataCase
      alias Quizaar.{Support.Factory, Repo}
    end
  end

  setup _ do
    Ecto.Adapters.SQL.Sandbox.mode(Quizaar.Repo, :manual)
  end

  def setup_sandbox(tags) do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Quizaar.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Quizaar.Repo, {:shared, self()})
    end

    :ok
  end
end
