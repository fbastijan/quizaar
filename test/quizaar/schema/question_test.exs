defmodule Quizaar.Schema.QuestionTest do
  use Quizaar.Support.SchemaCase
  alias Quizaar.Quizzes.Question

  @expected_fields_with_types [
    {:id, :binary_id},
    {:options, {:array, :string}},
    {:text, :string},
    {:answer, :string},
    {:used, :boolean},
    {:quiz_id, :binary_id},
    {:inserted_at, :utc_datetime},
    {:updated_at, :utc_datetime}
  ]
  @optional [
    :id,
    :used,
    :inserted_at,
    :updated_at
  ]

  describe "fields and types" do
    test "it has the correct field and types" do
      actual_fields_with_types =
        for field <- Question.__schema__(:fields) do
          type = Question.__schema__(:type, field)
          {field, type}
        end

      assert MapSet.new(actual_fields_with_types) == MapSet.new(@expected_fields_with_types)
    end
  end

  describe "changeset/2" do
    test "returns a valid changeset when given valid arguments" do
      valid_params = valid_params(@expected_fields_with_types) |> Map.put("used", false)
      changeset = Question.changeset(%Question{}, valid_params)

      assert %Ecto.Changeset{valid?: true, changes: changes} = changeset

      for {field, _} <- @expected_fields_with_types do
        actual = Map.get(changes, field)
        expected = valid_params[Atom.to_string(field)]

        assert actual == expected,
               "Values did not match for field: #{field}\n expected: #{inspect(expected)} \n actual: #{inspect(actual)} "
      end
    end

    test "error: returns an error changeset when given un-castable values" do
      invalid_params = invalid_params(@expected_fields_with_types)

      assert %Ecto.Changeset{valid?: false, errors: errors} =
               Question.changeset(%Question{}, invalid_params)

      for {field, _} <- @expected_fields_with_types do
        assert errors[field], "The field: #{field} is missing from errors"
        {_, meta} = errors[field]

        assert meta[:validation] == :cast,
               "The validation type, #{meta[:validation]}, is incorrect"
      end
    end

    test "error: returns an error changeset when required is missing" do
      invalid_params = %{}

      assert %Ecto.Changeset{valid?: false, errors: errors} =
               Question.changeset(%Question{}, invalid_params)

      for {field, _} <- @expected_fields_with_types, field not in @optional do
        assert errors[field], "The field: #{field} is missing from errors"
        {_, meta} = errors[field]

        assert meta[:validation] == :required,
               "The validation type, #{meta[:validation]}, is incorrect"
      end

      for field <- @optional do
        refute errors[field], "The optional field #{field} is required when it shouldnt be"
      end
    end
  end
end
