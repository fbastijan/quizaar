defmodule Quizaar.Quizzes.Result do
  use Ecto.Schema
  import Ecto.Changeset
  @optional_fields [:id, :inserted_at, :updated_at]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "results" do
    field :score, :integer

    belongs_to :quiz, Quizaar.Quizzes.Quiz
    belongs_to :player, Quizaar.Players.Player

    timestamps(type: :utc_datetime)
  end
 def all_fields do
    __MODULE__.__schema__(:fields)
  end
  @doc false
  def changeset(result, attrs) do
    result
    |> cast(all_fields(), attrs)
    |> validate_required(all_fields() -- @optional_fields)
  end
end
