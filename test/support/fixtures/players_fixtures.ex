defmodule Quizaar.PlayersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Quizaar.Players` context.
  """

  @doc """
  Generate a player.
  """
  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
      attrs
      |> Enum.into(%{
        name: "some name",
        session_id: "some session_id"
      })
      |> Quizaar.Players.create_player()

    player
  end
end
