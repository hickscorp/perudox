defmodule Perudox.Game do
  @moduledoc """
  This module is the GenServer interface around a `Perudox.Player.State` data
  structure.
  """

  use GenServer
  alias Perudox.{Game, Game.State}
  alias Perudox.{Bet, Player}

  # Public API.

  @type t :: pid

  @spec new :: Game.t
  def new do
    {:ok, game} = start_link()
    game
  end

  @spec start_link() :: {:ok, Game.t}
  def start_link, do: GenServer.start_link __MODULE__, %State{}

  @spec state(Game.t) :: State.t
  def state(game), do: GenServer.call game, :state

  @spec mode(Game.t) :: State.mode
  def mode(game), do: state(game).mode

  @spec phase(Game.t) :: State.phase
  def phase(game), do: state(game).phase

  @spec history(Game.t) :: list(Perudox.Bet.t)
  def history(game), do: state(game).history

  @spec players(Game.t) :: list(Player.t)
  def players(game), do: state(game).players

  @spec join(Game.t, Player.t) :: :ok
  def join(game, player), do: GenServer.call game, {:join, player}

  @spec start(Game.t) :: :ok
  def start(game), do: GenServer.call game, :start

  @spec bet(Game.t, Player.t, Bet.t) :: :ok | {:error, atom}
  def bet(game, player, bet), do: GenServer.call game, {:bet, player, bet}

  @spec dudo(Game.t, Player.t) :: :ok | {:error, atom}
  def dudo(game, player), do: GenServer.call game, {:dudo, player}

  # GenServer callbacks.

  @spec init(State.t) :: {:ok, State.t}
  def init(state), do: {:ok, state}

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join, player}, _from, state) do
    replify state, State.add_player(state, player)
  end

  def handle_call(:start, _from, state) do
    replify state, State.start(state)
  end

  def handle_call({:bet, player, bet}, _from, state) do
    replify state, State.bet(state, player, bet)
  end

  def handle_call({:dudo, player}, _from, state) do
    replify state, State.dudo(state, player)
  end

  defp replify(_, %State{} = state), do: {:reply, :ok, state}
  defp replify(state, {:error, _} = err), do: {:reply, err, state}
end
