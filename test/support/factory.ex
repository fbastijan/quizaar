defmodule Quizaar.Support.Factory do
  use ExMachina.Ecto, repo: Quizaar.Repo
  alias Quizaar.Accounts.Account
  alias Quizaar.Users.User
  alias Quizaar.Quizzes.Quiz
  alias Quizaar.Quizzes.Question
  alias Quizaar.Players.Player

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
  def quiz_factory do
     user = insert(:user)

    %Quiz{
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.paragraph(2..5),
     user: user,
    user_id: user.id

    }
  end
  def question_factory do
    %Quizaar.Quizzes.Question{
      text: Faker.Lorem.sentence(),
      answer: Faker.Lorem.word(),
      options: Enum.map(1..4, fn _ -> Faker.Lorem.word() end),
      used: false,
      quiz: build(:quiz)
    }

  end
  def player_factory do
    %Quizaar.Players.Player{
      user: build(:user),
      quiz: build(:quiz),
      session_id: Faker.UUID.v4(),
      name: Faker.Person.name()
    }
  end
end
