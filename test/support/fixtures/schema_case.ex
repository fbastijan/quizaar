defmodule Quizaar.Support.SchemaCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Ecto.Changeset
      import Quizaar.Support.SchemaCase
    end
  end

  def valid_params(fields_with_types) do
    valid_value_by_type = %{

      {:array, :string} => fn -> Enum.map(1..Enum.random(1..5), fn _ -> Faker.Lorem.word() end) end,
      {:array, Ecto.UUID} => fn -> Enum.map(1..Enum.random(1..5), fn _ -> Faker.UUID.v4() end) end,
      binary_id: fn -> Faker.UUID.v4() end,
      string: fn -> Faker.Lorem.word() end,
      utc_datetime: fn ->
        Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)
      end,
      integer: fn -> Enum.random(0..10) end,
      boolean: fn -> Enum.random([true, false]) end
    }

    for {field, type} <- fields_with_types, into: %{} do
      case field do
        :email -> {Atom.to_string(field), Faker.Internet.email()}
        _ -> {Atom.to_string(field), valid_value_by_type[type].()}
      end
    end
  end

  def invalid_params(fields_with_types) do
    valid_value_by_type = %{
          {:array, :string} => fn ->
        Enum.map(1..Enum.random(1..5), fn _ ->
          Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)
        end)
      end,

      {:array, Ecto.UUID} => fn ->
        Enum.map(1..Enum.random(1..5), fn _ ->
          Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)
        end)
      end,
      binary_id: fn ->
        Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)
      end,
      string: fn -> Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second) end,
      utc_datetime: fn -> Faker.Lorem.word() end,
      integer: fn ->
        Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)
      end,
      boolean: fn ->
        Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)
      end
    }

    for {field, type} <- fields_with_types, into: %{} do
      case field do
        :email ->
          {Atom.to_string(field),
           Faker.DateTime.backward(Enum.random(0..100)) |> DateTime.truncate(:second)}

        _ ->
          {Atom.to_string(field), valid_value_by_type[type].()}
      end
    end
  end
end
