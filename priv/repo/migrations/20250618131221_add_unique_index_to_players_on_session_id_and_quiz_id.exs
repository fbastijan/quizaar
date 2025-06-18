defmodule Quizaar.Repo.Migrations.AddUniqueIndexToPlayersOnSessionIdAndQuizId do
  use Ecto.Migration
def change do
  create unique_index(:players, [:session_id, :quiz_id])
end
end
