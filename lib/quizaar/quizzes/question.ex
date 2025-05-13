defmodule Quizaar.Quizzes.Question do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "questions" do
    field :options, {:array, :string}
    field :text, :string
    field :answer, :string
    field :quiz_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(question, attrs) do
    question
    |> cast(attrs, [:text, :options, :answer])
    |> validate_required([:text, :options, :answer])
  end
end
