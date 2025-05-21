defmodule Quizaar.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @optional_fields [:id, :biography, :full_name, :gender, :inserted_at, :updated_at]
  @foreign_key_type :binary_id
  schema "users" do
    field :full_name, :string
    field :gender, :string
    field :biography, :string
    belongs_to :account, Quizaar.Accounts.Account, type: :binary_id
    has_many :quiz, Quizaar.Quizzes.Quiz

    timestamps(type: :utc_datetime)
  end
  defp all_fields do
    __MODULE__.__schema__(:fields)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, all_fields())
    |> validate_required(all_fields() -- @optional_fields)
  end
end
