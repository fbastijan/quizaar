defmodule Quizaar.Repo.Migrations.AddUniqueIndexToResults do
  use Ecto.Migration

  def change do
      drop index(:results, [:player_id])
      create unique_index(:results, [:player_id])
  end
end
