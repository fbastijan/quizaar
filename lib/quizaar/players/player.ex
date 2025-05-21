defmodule Quizaar.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "players" do
    field :name, :string
    field :session_id, :string
    field :user_id, :binary_id
    belongs_to :quiz, Quizaar.Quizzes.Quiz
    has_one :result, Quizaar.Quizzes.Result
    has_many :answers, Quizaar.Quizzes.Answer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:session_id, :name])
    |> validate_required([:session_id, :name])
  end
end
