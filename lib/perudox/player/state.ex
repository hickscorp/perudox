defmodule Perudox.Player.State do
  @moduledoc """
  This module defines state for a player and facilitates interactions with it.
  """

  alias Perudox.Player.State

  @zero_occurences Map.new(1..6, fn k -> {k, 0} end)

  @type dice :: integer
  @type hand :: list(dice)
  @type count :: non_neg_integer
  @type occurences :: %{1 => count, 2 => count, 3 => count, 4 => count, 5 => count, 6 => count}

  @type t :: %State{nickname: String.t, hand: hand, game_over: boolean}
  defstruct nickname: nil, hand: [0, 0, 0, 0, 0], game_over: false

  @doc """
  Rolls the hand in the given state.

  ## Examples

    ```
    iex> hand = [5, 6, 7]
    iex> state = %Perudox.Player.State{hand: hand}
    iex> %{hand: new_hand} = Perudox.Player.State.roll state
    iex> hand != new_hand && length(hand) == length(new_hand)
    true
    ```
  """
  @spec roll(State.t) :: State.t
  def roll(%{hand: hand} = state) do
    %{state | hand: generate(hand)}
  end

  @doc """
  Adds a dice to a hand, unless that player is out or his hand is maxed out.

  ## Examples

    ```
    iex> hand = [1, 2, 3, 4]
    iex> state = %Perudox.Player.State{hand: hand}
    iex> %{hand: new_hand} = Perudox.Player.State.win_a_dice state
    iex> hand != new_hand && length(hand) == length(new_hand) - 1
    true
    ```
  """
  @spec win_a_dice(State.t) :: State.t | {:error, atom}
  def win_a_dice(%{hand: []}), do: {:error, :player_already_out}
  def win_a_dice(%{game_over: true}), do: {:error, :player_already_out}
  def win_a_dice(%{hand: hand}) when length(hand) >= 5, do: {:error, :hand_maxed_out}
  def win_a_dice(%{hand: hand} = state) do
    %{state | hand: [1 | hand]}
  end

  @doc """
  Removes a dice from a player's hand. If their last dice is being taken, the
  state is also maked as game over.

  ## Examples

    ```
    iex> hand = [1, 2, 3, 4]
    iex> state = %Perudox.Player.State{hand: hand}
    iex> %{hand: new_hand} = Perudox.Player.State.lose_a_dice state
    iex> hand != new_hand && length(hand) == length(new_hand) + 1
    true
    ```
  """
  @spec lose_a_dice(State.t) :: State.t | {:error, atom}
  def lose_a_dice(%{hand: []}), do: {:error, :player_already_out}
  def lose_a_dice(%{game_over: true}), do: {:error, :player_already_out}
  def lose_a_dice(%{hand: hand} = state) do
    %{state | hand: hand |> List.delete_at(0)}
      |> check_game_over
  end

  @doc """
  Counts occurences of each value in a hand.

  ## Examples

    ```
    iex> hand = [1, 2, 2, 3, 3, 3]
    iex> state = %Perudox.Player.State{hand: hand}
    iex> Perudox.Player.State.occurences state
    %{1 => 1, 2 => 2, 3 => 3, 4 => 0, 5 => 0, 6 => 0}
    ```

  """
  @spec occurences(State.t) :: occurences
  def occurences(%{hand: hand}) do
    Enum.reduce hand, @zero_occurences, fn (dice, acc) ->
      %{acc | dice => acc[dice] + 1}
    end
  end

  # Private functions.

  @spec check_game_over(State.t) :: State.t
  defp check_game_over(%{hand: hand} = state) do
    %{state | game_over: Enum.count(hand) == 0}
  end

  @spec generate(hand) :: hand
  defp generate(hand) do
    hand
      |> Enum.map(fn _ -> :rand.uniform(6) end)
      |> Enum.sort
  end
end
