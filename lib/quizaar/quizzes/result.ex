defmodule Quizaar.Quizzes.Result do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "results" do
    field :score, :integer
    field :player_id, :binary_id
    field :quiz_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:score])
    |> validate_required([:score])
  end
end
