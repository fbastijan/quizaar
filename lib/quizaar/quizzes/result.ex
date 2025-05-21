defmodule Quizaar.Quizzes.Result do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "results" do
    field :score, :integer

    belongs_to :player, Quizaar.Players.Player

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:score])
    |> validate_required([:score])
  end
end
