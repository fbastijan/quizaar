defmodule Quizaar.Players do
  @moduledoc """
  The Players context.
  """

  import Ecto.Query, warn: false
  alias Quizaar.Repo

  alias Quizaar.Players.Player

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players()
      [%Player{}, ...]

  """
  def list_players do
    Repo.all(Player)
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!(456)
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  def get_player(id), do: Repo.get(Player, id)

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end

  def count_players_for_quiz(quiz_id) do
    import Ecto.Query

    Quizaar.Repo.aggregate(
      from(p in Quizaar.Players.Player, where: p.quiz_id == ^quiz_id),
      :count,
      :id
    )
  end

  def get_player_by_session_id(session_id) do
    Repo.get_by(Player, session_id: session_id)
  end

  def get_player_by_session_id_and_quiz(session_id, quiz_id) do
    Repo.get_by(Player, session_id: session_id, quiz_id: quiz_id)
  end

  def get_player_by_user_and_quiz(user_id, quiz_id) do
    Repo.get_by(Player, user_id: user_id, quiz_id: quiz_id)
  end

  def get_player_by_user(user_id) do
    Repo.get_by(Player, user_id: user_id)
  end

  def get_players_by_quiz(quiz_id) do
    import Ecto.Query

    from(p in Player, where: p.quiz_id == ^quiz_id)
    |> Repo.all()
  end
end
