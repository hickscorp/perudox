defmodule Perudox.Game.State do
  @moduledoc """
  This module holds the state of a game. It also exposes functions to verify state,
  interact with it and transform it.
  """

  alias Perudox.Game.State
  alias Perudox.{Bet, Player}
  alias Perudox.Player.State, as: PlayerState

  @type phase :: :open | :bets
  @type mode :: :normal | :palifico
  @type players :: list(Player.t)
  @type t :: %State{
    phase: phase, mode: mode,
    previous_player: Player.t, players: players,
    first_player: Player.t, first_player_turn: boolean,
    history: list(Bet.t),
    dice_count: PlayerState.count, hand_counts: %{PlayerState.t => PlayerState.count}
  }
  defstruct [
    phase: :open, mode: :normal,
    previous_player: nil, players: [],
    first_player: nil, first_player_turn: true, history: [],
    dice_count: 0, hand_counts: %{}
  ]

  @spec add_player(State.t, Player.t) :: State.t | {:error, atom}
  def add_player(%{players: players}, _) when length(players) >= 4 do
    {:error, :max_players_reached}
  end
  def add_player(%{phase: phase}, _) when phase != :open do
    {:error, :game_already_started}
  end
  def add_player(%{players: players} = state, player) do
    if player in players do
      {:error, :cannot_join_twice}
    else
      %{state | players: players ++ [player]}
    end
  end

  @spec start(State.t) :: State.t | {:error, atom}
  def start(%{phase: phase}) when phase != :open do
    {:error, :game_already_started}
  end
  def start(%{players: []}) do
    {:error, :not_enough_players}
  end
  def start(state) do
    %{state | phase: :bets}
      |> first_will_start
      |> maintain_dice_counts
  end

  @spec bet(State.t, Player.t, Bet.t) :: State.t | {:error, atom}
  def bet(%{phase: phase}, _, _) when phase != :bets do
    {:error, :not_in_bets_phase}
  end
  def bet(%{players: [player | _]}, actor, _) when actor != player do
    {:error, :invalid_turn}
  end
  def bet(%{mode: :normal, history: []}, _, %{value: 1}) do
    {:error, :cannot_start_with_aces}
  end
  def bet(%{mode: :palifico, first_player_turn: false, history: [%{value: v2} | _]}, _, %{value: v}) when v != v2 do
    {:error, :cannot_change_value_in_palifico}
  end
  def bet(state, _player, bet) do
    with :ok <- bet_allowed?(state, bet) do
      state
        |> place_bet(bet)
        |> cycle_players
    end
  end

  @spec dudo(State.t, Player.t) :: State.t | {:error, atom}
  def dudo(%{phase: phase}, _player) when phase != :bets do
    {:error, :not_in_bets_phase}
  end
  def dudo(%{players: [player | _]}, actor) when actor != player do
    {:error, :invalid_turn}
  end
  def dudo(%{previous_player: prev, players: [cur | _]} = state, _) do
    looser = if bet_fulfilled?(state), do: cur, else: prev
    looser |> Player.lose_a_dice
    state
      |> maintain_dice_counts
      |> cycle_players_until(looser)
  end

  @spec calzo(State.t, Player.t) :: State.t | {:error, atom}
  def calzo(%{phase: phase}, _player) when phase != :bets do
    {:error, :not_in_bets_phase}
  end
  def calzo(%{mode: :palifico}, _player) do
    {:error, :calzo_not_allowed_during_palifico}
  end
  def calzo(%{players: [_, _]}, _player) do
    {:error, :calzo_not_allowd_in_duel}
  end
  def calzo(%{history: []}, _player) do
    {:error, :no_bet_yet}
  end
  def calzo(%{players: [player | _], previous_player: player}, _player) do
    {:error, :invalid_turn}
  end
  def calzo(state, player) do
    state
      |> handle_calzo(player, length(Player.state(player).hand))
  end

  # Private functions.

  @spec bet_allowed?(State.t, Bet.t) :: :ok | {:error, atom}
  def bet_allowed?(%{history: []}, bet) do
    with :ok <- Bet.legal_count?(bet.count),
         do:    Bet.legal_value?(bet.value)
  end
  def bet_allowed?(%{history: [lb | _]} = state, bet) do
    with :ok <- Bet.legal_count?(bet.count),
         :ok <- Bet.legal_value?(bet.value),
         do:    Bet.stronger?(state.mode, bet, lb)
  end

  @spec bet_fulfilled?(State.t) :: boolean
  def bet_fulfilled?(%{mode: mode, history: [lb | _]} = state) do
    count = occurences_of mode, occurences(state), lb.value
    lb.count <= count
  end

  @spec bet_exactly_fulfilled?(State.t) :: boolean
  def bet_exactly_fulfilled?(%{mode: mode, history: [lb | _]} = state) do
    lb.count == occurences_of mode, occurences(state), lb.value
  end

  @spec cycle_players_until(State.t, Player.t) :: State.t
  def cycle_players_until(%{players: [until | _]} = state, until), do: state
  def cycle_players_until(state, until), do: cycle_players_until cycle_players(state), until

  @spec cycle_players(State.t) :: State.t
  defp cycle_players(%{players: players} = state) do
    [previous | rest] = players
    %{state | previous_player: previous, players: rest ++ [previous]}
      |> detect_first_player_turn
  end

  @spec detect_first_player_turn(State.t) :: State.t
  defp detect_first_player_turn(%{players: [p | _], first_player: fp} = state) do
    %{state | first_player_turn: p == fp}
  end

  @spec first_will_start(State.t) :: State.t
  defp first_will_start(%{players: [fp | _]} = state) do
    %{state | first_player: fp}
      |> detect_first_player_turn
  end

  @spec maintain_dice_counts(State.t) :: State.t
  defp maintain_dice_counts(state) do
    state
      |> count_hands
      |> count_dice
  end

  @spec count_hands(State.t) :: State.t
  defp count_hands(%{players: players} = state) do
    count = players
      |> Enum.map(fn p -> {p, Player.hand p} end)
      |> Enum.into(%{})
    %{state | hand_counts: count}
  end

  @spec count_dice(State.t) :: State.t
  defp count_dice(%{hand_counts: hand_counts} = state) do
    count = hand_counts
      |> Enum.reduce(0, fn {_, hand}, acc -> acc + length(hand) end)
    %{state | dice_count: count}
  end

  @spec place_bet(State.t, Bet.t) :: State.t
  defp place_bet(%{history: history} = state, bet) do
    %{state | history: [bet | history]}
  end

  @spec handle_calzo(State.t, Player.t, PlayerState.count) :: State.t | {:error, atom}
  def handle_calzo(_, _, 5) do
    {:error, :hand_maxed_out}
  end
  def handle_calzo(state, player, _) do
    (case bet_exactly_fulfilled? state do
      true -> &Player.win_a_dice/1
      _ -> &Player.lose_a_dice/1
    end).(player)
    state
      |> maintain_dice_counts
  end

  def occurences_of(_mode, data, 1), do: data[1]
  def occurences_of(:normal, data, value), do: data[value] + data[1]
  def occurences_of(:palifico, data, value), do: data[value]

  @spec occurences(State.t) :: PlayerState.occurences
  def occurences(%{players: players}) do
    players
      |> Enum.map(&Player.occurences/1)
      |> Enum.reduce(&Map.merge(&1, &2, fn _k, a, b -> a + b end))
  end
end
