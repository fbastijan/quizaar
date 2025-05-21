defmodule Quizaar.Repo.Migrations.AddJoinCode do
  use Ecto.Migration

  def change do
      alter table(:quizzes) do
        add :join_code, :string
      end
      create unique_index(:quizzes, [:join_code])
  end
end
