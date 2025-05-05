defmodule QuizaarWeb.AccountJSON do
  alias Quizaar.Accounts.Account
  alias QuizaarWeb.UserJSON

  @doc """
  Renders a list of accounts.
  """
  def index(%{accounts: accounts}) do
    %{data: for(account <- accounts, do: data(account))}
  end

  @doc """
  Renders a single account.
  """
  def show(%{account: account}) do
    %{data: data(account)}
  end

  defp data(%Account{} = account) do
    %{
      id: account.id,
      email: account.email,
      hash_password: account.hash_password
    }
  end

  def show2(%{account: account, token: token}) do
    %{
      id: account.id,
      email: account.email,
      token: token
    }
  end

  def show_full_account(%{account: account}) do
    %{
      id: account.id,
      email: account.email,
      user: UserJSON.data(account.user)
    }
  end
end
