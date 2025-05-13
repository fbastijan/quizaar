defmodule QuizaarWeb.ResultJSON do
  alias Quizaar.Quizzes.Result

  @doc """
  Renders a list of results.
  """
  def index(%{results: results}) do
    %{data: for(result <- results, do: data(result))}
  end

  @doc """
  Renders a single result.
  """
  def show(%{result: result}) do
    %{data: data(result)}
  end

  defp data(%Result{} = result) do
    %{
      id: result.id,
      score: result.score
    }
  end
end
