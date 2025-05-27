defmodule Quizaar.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "players" do
    field :name, :string
    field :session_id, :string
    belongs_to :user, Quizaar.Accounts.User
    belongs_to :quiz, Quizaar.Quizzes.Quiz
    has_one :result, Quizaar.Quizzes.Result
    has_many :answers, Quizaar.Quizzes.Answer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:session_id, :name, :quiz_id, :user_id])
    |> validate_required([:quiz_id])
    |> unique_constraint(:session_id, name: :players_session_id_index)
    |> unique_constraint(:user_id, name: :players_user_id_quiz_id_index)
  end
end
