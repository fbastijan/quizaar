defmodule Quizaar.Repo.Migrations.AddQuizReferenceToResult do
  use Ecto.Migration

  def change do
    alter table(:results) do
      add :quiz_id, references(:quizzes, type: :binary_id)
    end
  end
end
