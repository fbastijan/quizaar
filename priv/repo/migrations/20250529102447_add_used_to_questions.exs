defmodule Quizaar.Repo.Migrations.AddUsedToQuestions do
  use Ecto.Migration

  def change do
   alter table(:questions) do
      add :used, :boolean, default: false, null: false
    end
  end
end
