defmodule Quizaar.Support.Factory do
  use ExMachina.Ecto, repo: Quizaar.Repo
  alias Quizaar.Accounts.Account
  alias Quizaar.Users.User
  alias Quizaar.Tournaments.{Tournament, Player, Match}

  def account_factory do
    %Account{
      email: Faker.Internet.email(),
      hash_password: Faker.Internet.slug()
    }
  end

  def user_factory do
    %User{
      full_name: Faker.Person.name(),
      gender: Enum.random(["male", "female"]),
      biography: Faker.Lorem.paragraph(2..5),
      account: build(:account)
    }
  end
end
