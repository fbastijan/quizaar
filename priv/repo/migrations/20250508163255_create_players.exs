defmodule Quizaar.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :session_id, :string
      add :name, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :quiz_id, references(:quizzes, on_delete: :nothing, type: :binary_id)
      timestamps(type: :utc_datetime)
    end

    create index(:players, [:user_id])
  end
end
