defmodule Quizaar.Quizzes.Quiz do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "quizzes" do
    field :description, :string
    field :title, :string
    field :join_code, :string
    belongs_to :user, Quizaar.Users.User
    has_many :questions, Quizaar.Quizzes.Question
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, [:title, :description, :user_id])
    |> validate_required([:title, :description])
    |> put_join_code()
     |> unique_constraint(:join_code)
  end


   defp put_join_code(changeset) do
    if get_field(changeset, :join_code) do
      changeset
    else
      changeset
      |> put_change(:join_code, generate_unique_code())
    end
  end

  defp generate_unique_code do

    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 6)
  end
end
