defmodule Quizaar.Schema.AccountTest do
  use Quizaar.Support.SchemaCase
  alias Quizaar.Accounts.Account

  @expected_fields_with_types [
    {:id, :binary_id},
    {:email, :string},
    {:hash_password, :string},
    {:inserted_at, :utc_datetime},
    {:updated_at, :utc_datetime}
  ]
  @optional [
    :id,
    :inserted_at,
    :updated_at
  ]

  describe "fields and types" do
    test "it has the correct field and types" do
      actual_fields_with_types =
        for field <- Account.__schema__(:fields) do
          type = Account.__schema__(:type, field)
          {field, type}
        end

      assert MapSet.new(actual_fields_with_types) == MapSet.new(@expected_fields_with_types)
    end
  end

  describe "changeset/2" do
    test "returns a valid changeset when given valid arguments" do
      valid_params = valid_params(@expected_fields_with_types)
      changeset = Account.changeset(%Account{}, valid_params)

      assert %Changeset{valid?: true, changes: changes} = changeset

      for {field, _} <- @expected_fields_with_types do
        actual = Map.get(changes, field)
        expected = valid_params[Atom.to_string(field)]

        if field == :hash_password do
          assert Bcrypt.verify_pass(valid_params["hash_password"], actual),
                 "Password: #{valid_params["hash_password"]} does not match hash: #{inspect(actual)}"
        else
          assert actual == expected,
                 "Values did not match for field: #{field}\n expected: #{inspect(expected)} \n actual: #{inspect(actual)} "
        end
      end
    end

    test "error: returns error changeset when an email is reused" do
      Ecto.Adapters.SQL.Sandbox.checkout(Quizaar.Repo)

      {:ok, existing_account} =
        %Account{}
        |> Account.changeset(valid_params(@expected_fields_with_types))
        |> Quizaar.Repo.insert()

      changeset_with_repeated_email =
        %Account{}
        |> Account.changeset(
          valid_params(@expected_fields_with_types)
          |> Map.put("email", existing_account.email)
        )

      assert {:error, %Changeset{valid?: false, errors: errors}} =
               Quizaar.Repo.insert(changeset_with_repeated_email)

      assert errors[:email], "The field :email is missing in errors."

      {_, meta} = errors[:email]

      assert meta[:constraint] == :unique,
             "The validation type, #{meta[:validation]}, is inncorect"
    end

    test "error: returns an error changeset when given un-castable values" do
      invalid_params = invalid_params(@expected_fields_with_types)

      assert %Changeset{valid?: false, errors: errors} =
               Account.changeset(%Account{}, invalid_params)

      for {field, _} <- @expected_fields_with_types do
        assert errors[field], "The field: #{field} is missing from errors"

        {_, meta} = errors[field]

        assert meta[:validation] == :cast,
               "The validation type, #{meta[:validation]}, is incorrect"
      end
    end

    test "error: returns an error changeset when when required is missing" do
      invalid_params = %{}

      assert %Changeset{valid?: false, errors: errors} =
               Account.changeset(%Account{}, invalid_params)

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
