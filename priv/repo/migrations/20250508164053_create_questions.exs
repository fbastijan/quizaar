defmodule Quizaar.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :string
      add :options, {:array, :string}
      add :answer, :string
      add :quiz_id, references(:quizzes, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:questions, [:quiz_id])
  end
end
