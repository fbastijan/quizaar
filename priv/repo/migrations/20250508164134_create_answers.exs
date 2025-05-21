defmodule Quizaar.Repo.Migrations.CreateAnswers do
  use Ecto.Migration

  def change do
    create table(:answers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string
      add :is_correct, :boolean, default: false, null: false
      add :player_id, references(:players, on_delete: :nothing, type: :binary_id)
      add :question_id, references(:questions, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:answers, [:question_id])
  end
end
