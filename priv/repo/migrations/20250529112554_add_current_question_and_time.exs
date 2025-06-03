defmodule Quizaar.Repo.Migrations.AddCurrentQuestionAndTime do
  use Ecto.Migration

  def change do
    alter table(:quizzes) do
      add :current_question_id, references(:questions, type: :binary_id)
      add :question_started_at, :utc_datetime
      # seconds
      add :question_time_limit, :integer
    end
  end
end
