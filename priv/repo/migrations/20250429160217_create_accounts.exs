defmodule Quizaar.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :hash_password, :string
      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all), null: true

      timestamps(type: :utc_datetime)
    end
    create unique_index(:accounts, [:email])
  end
end
