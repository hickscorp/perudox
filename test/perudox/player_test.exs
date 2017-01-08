defmodule Perudox.PlayerTest do
  @moduledoc """
  """
  use ExUnit.Case, async: true
  doctest Perudox.Player

  alias Perudox.Player

  @nickname "Doodloo"
  @hand [1, 2, 3, 4, 5]
  @occurences %{1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 0}

  setup do
    player = Player.new @nickname
    Player.set_hand player, @hand
    {:ok, %{player: player}}
  end

  test "creating a new player with a nickname", %{player: player} do
    assert Player.state(player).nickname == @nickname
  end

  test "retrieving a player's state", %{player: player} do
    %{nickname: nickname, game_over: false} = Player.state player
    assert nickname == @nickname
  end

  test "retrieving a player's nickname", %{player: player} do
    assert Player.nickname(player) == @nickname
  end

  test "retrieving a player's hand", %{player: player} do
    assert Player.hand(player) == @hand
  end

  test "retrieving a player's occurences", %{player: player} do
    assert Player.occurences(player) == @occurences
  end

  test "setting hand then rolling dice", %{player: player} do
    initial_hand = [1, 2, 3, 4, 0]
    Player.set_hand player, initial_hand
    hand = Player.hand player
    assert hand == initial_hand

    :ok = Player.roll player
    hand = Player.hand player
    assert hand != initial_hand
    assert length(hand) == length(initial_hand)
  end

  test "winning and loosing a dice", %{player: player} do
    Player.set_hand player, [1, 2, 3, 4]
    Player.win_a_dice player
    assert length(Player.hand(player)) == 5
    Player.win_a_dice player
    assert length(Player.hand(player)) == 5
    Player.lose_a_dice player
    assert length(Player.hand(player)) == 4
    assert !Player.game_over? player
    Enum.each 1..5, fn _ -> Player.lose_a_dice player end
    assert length(Player.hand(player)) == 0
    assert Player.game_over? player
  end
end
