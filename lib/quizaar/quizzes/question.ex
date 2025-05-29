defmodule Quizaar.Quizzes.Question do
  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields [:id, :used, :inserted_at, :updated_at]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "questions" do
    field :options, {:array, :string}
    field :text, :string
    field :answer, :string
    field :used, :boolean, default: false
    belongs_to :quiz, Quizaar.Quizzes.Quiz
    has_many :answers, Quizaar.Quizzes.Answer
    timestamps(type: :utc_datetime)
  end

  @doc false
defp all_fields do
    __MODULE__.__schema__(:fields)
  end
  def changeset(question, attrs) do
    question
    |> cast(attrs, all_fields())
    |> validate_required(all_fields() -- @optional_fields)
  end
end
