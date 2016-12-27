defmodule Perudox.Player do
  @moduledoc """
  This module is the GenServer interface around a `Perudox.Player.State` data
  structure.
  """

  use GenServer
  alias Perudox.{Player, Player.State}

  @type t :: pid

  # Public API.

  @spec new(String.t) :: Player.t
  def new(nickname) do
    with {:ok, player} <- start_link %State{nickname: nickname} do
      player
    end
  end

  @spec start_link(State.t) :: {:ok, Player.t}
  def start_link(state) do
    GenServer.start_link __MODULE__, state
  end

  @spec state(Player.t) :: State.t
  def state(player), do: GenServer.call player, :state

  @spec nickname(Player.t) :: String.t
  def nickname(player), do: state(player).nickname

  @spec hand(Player.t) :: State.hand
  def hand(player), do: state(player).hand

  @spec occurences(Player.t) :: State.occurences
  def occurences(player), do: GenServer.call player, :occurences

  @spec roll(Player.t) :: :ok
  def roll(player), do: GenServer.call player, :roll

  @spec set_hand(Player.t, State.hand) :: :ok
  def set_hand(player, hand), do: GenServer.call player, {:set_hand, hand}

  @spec win_a_dice(Player.t) :: :ok
  def win_a_dice(player), do: GenServer.call player, :win_a_dice

  @spec lose_a_dice(Player.t) :: :ok
  def lose_a_dice(player), do: GenServer.call player, :lose_a_dice

  # GenServer callback.

  @spec init(State.t) :: {:ok, State.t}
  def init(state), do: {:ok, state}

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:occurences, _from, state) do
    {:reply, State.occurences(state), state}
  end

  def handle_call(:roll, _from, state) do
    replify state, State.roll(state)
  end

  def handle_call({:set_hand, hand}, _from, state) do
    replify state, %{state | hand: hand}
  end

  def handle_call(:win_a_dice, _from, state) do
    replify state, State.win_a_dice(state)
  end

  def handle_call(:lose_a_dice, _from, state) do
    replify state, State.lose_a_dice(state)
  end

  defp replify(_, %State{} = state), do: {:reply, :ok, state}
  defp replify(state, {:error, _} = err), do: {:reply, err, state}
end
