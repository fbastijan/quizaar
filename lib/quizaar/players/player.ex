defmodule Quizaar.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset
  @optional_fields [:id, :inserted_at, :updated_at, :session_id, :name, :user_id]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "players" do
    field :name, :string
    field :session_id, :string
    belongs_to :user, Quizaar.Users.User
    belongs_to :quiz, Quizaar.Quizzes.Quiz
    has_one :result, Quizaar.Quizzes.Result
    has_many :answers, Quizaar.Quizzes.Answer
    timestamps(type: :utc_datetime)
  end

  defp all_fields do
    __MODULE__.__schema__(:fields)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, all_fields())
    |> validate_required(all_fields() -- @optional_fields)
      |> unique_constraint([:session_id, :quiz_id])
    |> unique_constraint(:user_id, name: :players_user_id_quiz_id_index)
  end
end
