defmodule Quizaar.Repo.Migrations.CreateResults do
  use Ecto.Migration

  def change do
    create table(:results, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :score, :integer
      add :player_id, references(:players, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:results, [:player_id])
  end
end
