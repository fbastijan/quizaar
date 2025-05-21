defmodule Quizaar.Quizzes.Answer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "answers" do
    field :text, :string
    field :is_correct, :boolean, default: false
    belongs_to :question, Quizaar.Quizzes.Question
    belongs_to :player, Quizaar.Players.Player
  end

  @doc false
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, [:text, :is_correct])
    |> validate_required([:text, :is_correct])
  end
end
