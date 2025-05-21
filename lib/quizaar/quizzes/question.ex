defmodule Quizaar.Quizzes.Question do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "questions" do
    field :options, {:array, :string}
    field :text, :string
    field :answer, :string
    belongs_to :quiz, Quizaar.Quizzes.Quiz
    has_many :answers, Quizaar.Quizzes.Answer
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :options, :answer, :quiz_id])
    |> validate_required([:text, :options, :answer, :quiz_id])
  end
end
