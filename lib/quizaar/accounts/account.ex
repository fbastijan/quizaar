defmodule Quizaar.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts" do
    field :email, :string
    field :hash_password, :string
    has_one :user, Quizaar.Users.User
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:email, :hash_password])
    |> validate_required([:email, :hash_password])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have @ sign and no spaces")
    |> validate_length(:email, min: 3, max: 160)
    |> put_password_hash()
  end

  defp put_password_hash(
    %Ecto.Changeset{valid?: true, changes: %{hash_password: hash_password}} = changeset
  ) do
      change(changeset, hash_password: Bcrypt.hash_pwd_salt(hash_password))
    end

  defp put_password_hash(changeset), do: changeset

end
