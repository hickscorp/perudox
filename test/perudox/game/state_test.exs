defmodule Perudox.Game.StateTest do
  @moduledoc """
  """
  use ExUnit.Case, async: true
  doctest Perudox.Game.State

  alias Perudox.Game.State
  alias Perudox.{Bet, Player}

  @small_hand [2, 3, 4, 5]
  @normal_hand [1, 2, 3, 4, 5]

  describe "adding players" do
    test "works when there are less than four" do
      {players, new_player} = {create_players(3), create_player("Test")}
      %{players: players_after_adding} = State.add_player %State{players: players}, new_player
      assert List.last(players_after_adding) == new_player
    end

    test "errors when trying to add the same player twice" do
      player = create_player "Test"
      ret = State.add_player %{players: [player]}, player
      assert ret == {:error, :cannot_join_twice}
    end

    test "errors when game is full" do
      {players, new_player} = {create_players(4), create_player("Test")}
      ret = State.add_player %State{players: players}, new_player
      assert ret == {:error, :max_players_reached}
    end
  end

  describe "starting the game" do
    setup do
      players = create_players 4, @normal_hand
      state = State.start %State{players: players}
      {:ok, %{players: players, state: state}}
    end

    test "prepares the state correctly", %{state: state, players: [p1, p2, p3, p4] = players} do
      %{phase: :bets,
        turn: 1,
        first_player_turn: true,
        dice_count: dc,
        hand_counts: %{^p1 => @normal_hand, ^p2 => @normal_hand, ^p3 => @normal_hand, ^p4 => @normal_hand},
        players: [first_player | _] = players_after_starting,
        first_player: first_player
      } = state

      assert players == players_after_starting
      assert dc == 5 * length players
    end
  end

  describe "betting" do
    setup do
      players = create_players 4
      state = State.start %State{players: players}
      {:ok, %{state: state}}
    end

    Enum.each ~w(open closed)a, fn phase ->
      test "is not allowed if the game is in the #{phase} phase", %{state: %{players: [player | _]} = state} do
        state = %{state | phase: unquote(phase)}
        ret = state |> State.bet(player, %Bet{count: 1, value: 2})
        assert ret == {:error, :not_in_bets_phase}
      end
    end

    test "errors if it's not the player's turn", %{state: state} do
      %{players: [_, p2 | _]} = state
      bet = %Bet{count: 1, value: 2}
      ret = state |> State.bet(p2, bet)
      assert ret == {:error, :invalid_turn}
    end

    test "cannot start with aces during normal mode", %{state: %{players: [p | _]} = state} do
      bet = %Bet{count: 1, value: 1}
      ret = State.bet state, p, bet
      assert ret == {:error, :cannot_start_with_aces}
    end

    test "can start with aces during palifico", %{state: %{players: [p1 | _]} = state} do
      bet = %Bet{count: 1, value: 1}
      %{history: history} = State.bet %{state | mode: :palifico}, p1, bet
      assert hd(history) == bet
    end

    test "errors when a player changes value in palifico unless first player", %{state: %{players: [p1, p2 | _]} = state} do
      ret = %{state | mode: :palifico}
        |> State.bet(p1, %Bet{count: 1, value: 1})
        |> State.bet(p2, %Bet{count: 2, value: 2})
      assert ret == {:error, :cannot_change_value_in_palifico}
    end

    test "can change value if in first player turn during palifico", %{state: %{players: [p1, p2, p3, p4]} = state} do
      bet = %Bet{count: 4, value: 2}
      %{history: history, turn: turn} = %{state | mode: :palifico}
        |> State.bet(p1, %Bet{count: 1, value: 1})
        |> State.bet(p2, %Bet{count: 2, value: 1})
        |> State.bet(p3, %Bet{count: 3, value: 1})
        |> State.bet(p4, %Bet{count: 4, value: 1})
        |> State.bet(p1, bet)
      assert hd(history) == bet
      assert turn == 1
    end

    test "errors if the bet is too weak", %{state: %{players: [p1, p2 | _]} = state} do
      {bet1, bet2} = {%Bet{count: 3, value: 3}, %Bet{count: 3, value: 3}}
      ret = state |> State.bet(p1, bet1) |> State.bet(p2, bet2)
      assert ret == {:error, :bet_too_weak}
    end

    test "is does its job on a successful bet", %{state: state} do
      %{players: [p1, p2, p3, p4]} = state
      bet = %Bet{count: 1, value: 2}
      %{
        turn: 1,
        history: [^bet],
        players: [^p2, ^p3, ^p4, ^p1],
        first_player_turn: false,
        previous_player: ^p1
      } = State.bet state, p1, bet
    end
  end

  describe "dudoing" do
    setup do
      players = create_players 4
      state = State.start %State{players: players}
      {:ok, %{state: state}}
    end

    Enum.each ~w(open closed)a, fn phase ->
      test "is not allowed if the game is in the #{phase} phase", %{state: %{players: [player | _]} = state} do
        state = %{state | phase: unquote(phase)}
        ret = state |> State.dudo(player)
        assert ret == {:error, :not_in_bets_phase}
      end
    end

    test "errors if it's not the player's turn", %{state: %{players: [_, p2 | _]} = state} do
      ret = state |> State.dudo(p2)
      assert ret == {:error, :invalid_turn}
    end

    @dudos [
      {5, 3, 4, "wrong"},
      {3, 4, 3, "right"}
    ]

    Enum.each @dudos, fn {count, p1_hand, p2_hand, msg} ->
      test "when the bet is " <> msg, %{state: %{players: [p1, p2 | _]} = state} do
        %{turn: turn} = state
          |> State.bet(p1, %Bet{count: unquote(count), value: 2})
          |> State.dudo(p2)
        assert turn == 2
        %{hand: hand} = Player.state p1
        assert length(hand) == unquote(p1_hand)
        %{hand: hand} = Player.state p2
        assert length(hand) == unquote(p2_hand)
      end
    end
  end

  describe "calzoing" do
    setup do
      players = create_players 4
      state = State.start %State{players: players, history: [%Bet{count: 1, value: 2}]}
      {:ok, %{state: state}}
    end

    Enum.each ~w(open closed)a, fn phase ->
      test "is not allowed if the game is in the #{phase} phase", %{state: %{players: [player | _]} = state} do
        state = %{state | phase: unquote(phase)}
        ret = state |> State.calzo(player)
        assert ret == {:error, :not_in_bets_phase}
      end
    end

    test "works even if it's not the player's turn", %{state: %{players: [_, p2 | _]} = state} do
      %{turn: turn} = state
        |> State.calzo(p2)
      assert turn == 2
    end

    @calzos [
      {3, 3, "wrong"},
      {4, 5, "right"}
    ]

    Enum.each @calzos, fn {count, hand, msg} ->
      test "when the check is " <> msg, %{state: %{players: [p1, p2 | _]} = state} do
        %{turn: turn} = state
          |> State.bet(p1, %Bet{count: unquote(count), value: 2})
          |> State.calzo(p2)
        assert turn == 2
        %{hand: hand} = Player.state p2
        assert length(hand) == unquote(hand)
      end
    end
  end

  describe "counting occurences" do
    @occurence_tests [
      {:normal,   1, 10, [{1, 10}],           "aces"},
      {:normal,   2, 10, [{2, 10}],           "twos"},
      {:normal,   2, 20, [{1, 10}, {2, 10}],  "twos with aces"},
      {:palifico, 1, 10, [{1, 10}],           "aces"},
      {:palifico, 2, 10, [{2, 10}],           "twos"},
      {:palifico, 2, 10, [{1, 10}, {2, 10}],  "twos with aces"},
    ]
    @zero_occurences Map.new(1..6, fn k -> {k, 0} end)
    @expected_occurences %{1 => 0, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 0}
    test "generally" do
      players = create_players 4
      occurences = %{players: players} |> State.occurences
      assert occurences == @expected_occurences
    end

    Enum.each @occurence_tests, fn {mode, value, count, data, msg} ->
      msg = "individually by " <> msg <> " in #{inspect mode} mode"
      test msg do
        data = Enum.reduce unquote(data), @zero_occurences, fn {value, count}, acc -> %{acc | value => count} end
        assert unquote(count) == State.occurences_of unquote(mode), data, unquote(value)
      end
    end
  end

  defp create_players(count, hand \\ @small_hand) do
    create_players count, hand, []
  end
  defp create_players(0, _, list) do
    list
  end
  defp create_players(count, hand, list) do
    create_players count - 1, hand, list ++ [create_player(count, hand)]
  end

  defp create_player(i, hand \\ @small_hand) do
    player = Player.new "Player #{to_string i}"
    Player.set_hand player, hand
    player
  end
end
