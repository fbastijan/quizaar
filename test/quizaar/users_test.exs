defmodule Quizaar.UsersTest do
  use Quizaar.Support.DataCase
  alias Quizaar.{Users, Users.User}
  alias Quizaar.{Accounts, Accounts.Account}

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Quizaar.Repo)
  end

  describe "create_user/1" do
    test "suvvess: it inserts an user in the db and returns the user" do
      acc = Factory.params_for(:account)
      user_params = Factory.params_for(:user)
      {:ok, %Account{} = returned_acc} = Accounts.create_account(acc)

      assert {:ok, %User{} = returned_user} = Users.create_user(returned_acc, user_params)

      user_from_db = Repo.get(User, returned_user.id)

      assert returned_user == user_from_db

      for {param_field, expected} <- user_params do
        param_field_string = to_string(param_field)
        schema_field = String.to_existing_atom(param_field_string)
        actual = Map.get(user_from_db, schema_field)

        assert actual == expected,
               "Value did not match for field: #{param_field} \n expected: #{expected}, \n actual: #{actual}"

        assert user_from_db.inserted_at == returned_user.updated_at
      end
    end
  end
end
