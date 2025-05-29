defmodule Quizaar.Quizzes.Quiz do
  use Ecto.Schema
  import Ecto.Changeset
  @optional_fields [:id, :inserted_at, :updated_at, :current_question_id, :question_started_at, :question_time_limit, :join_code]
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "quizzes" do
    field :description, :string
    field :title, :string
    field :join_code, :string
    belongs_to :user, Quizaar.Users.User
    has_many :questions, Quizaar.Quizzes.Question

    belongs_to :current_question, Quizaar.Quizzes.Question, foreign_key: :current_question_id, type: :binary_id
    field :question_started_at, :utc_datetime
    field :question_time_limit, :integer
    timestamps(type: :utc_datetime)
  end
  def all_fields do
    __MODULE__.__schema__(:fields)
  end
  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, all_fields())
    |> validate_required(all_fields() -- @optional_fields)
    |> put_join_code()
    |> unique_constraint(:join_code)
  end


   defp put_join_code(changeset) do
    if get_field(changeset, :join_code) do
      changeset
    else
      changeset
      |> put_change(:join_code, generate_unique_code())
    end
  end

  defp generate_unique_code do

    :crypto.strong_rand_bytes(4)
    |> Base.encode16()
    |> binary_part(0, 6)
  end
end
