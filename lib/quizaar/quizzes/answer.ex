defmodule Quizaar.Quizzes.Answer do
  use Ecto.Schema
  import Ecto.Changeset
  @optional_fields [:id, :is_correct, :inserted_at, :updated_at]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "answers" do
    field :text, :string
    field :is_correct, :boolean, default: false
    belongs_to :question, Quizaar.Quizzes.Question
    belongs_to :player, Quizaar.Players.Player
     timestamps(type: :utc_datetime)
  end

  defp all_fields do
    __MODULE__.__schema__(:fields)
  end
  @doc false
  def changeset(answer, attrs) do
    answer
    |> cast(attrs, all_fields())
    |> validate_required(all_fields() -- @optional_fields)


  end
end
