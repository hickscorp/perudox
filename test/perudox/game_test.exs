defmodule Perudox.GameTest do
  @moduledoc """
  """
  use ExUnit.Case, async: true
  doctest Perudox.Game

  alias Perudox.Game
  alias Perudox.Player

  @normal_hand [1, 2, 3, 4, 5]
  @nicknames ~w(Gina Pierre Tooth Go Lily)

  test "playing a full game turn" do
    game = Game.new
    # Empty game shouldn't start.
    ret = Game.start game
    assert ret == {:error, :not_enough_players}
    # Create some players with a deterministic hand.
    players = Enum.map @nicknames, &Player.new/1
    Enum.each players, &(Player.set_hand &1, @normal_hand)
    # Join the game.
    ret = Enum.map players, fn player -> Game.join game, player end
    assert ret == [:ok, :ok, :ok, :ok, {:error, :max_players_reached}]
    # Deconstruct players.
    [gina, pierre, tooth, go, lily] = players
    assert gina != pierre and pierre != tooth and tooth != go and go != lily
    # Cannot bet if game not started.
    ret = Game.bet game, gina, %{count: 1, value: 2}
    assert ret == {:error, :not_in_bets_phase}
    # Getting things from the game.
    %{players: players} = Game.state game
    assert players == [gina, pierre, tooth, go]
    assert Game.phase(game) == :open
    assert Game.mode(game) == :normal
    assert Game.history(game) == []
    assert Game.players(game) == players
    # Start the game.
    ret = Game.start game
    assert ret == :ok
    # Place a first bet.
    ret = Game.bet game, gina, %{count: 1, value: 2}
    assert ret == :ok
    # Cannot bet unless it's the player's turn.
    ret = Game.bet game, gina, %{count: 1, value: 2}
    assert ret == {:error, :invalid_turn}
    # Cannot bet with a weaker bet.
    ret = Game.bet game, pierre, %{count: 1, value: 2}
    assert ret == {:error, :bet_too_weak}
    # Can bet higher.
    ret = Game.bet game, pierre, %{count: 2, value: 2}
    assert ret == :ok
    # Cannot counter unless it's the player's turn.
    ret = Game.dudo game, pierre
    assert ret == {:error, :invalid_turn}
    # Can counter.
    ret = Game.dudo game, tooth
    assert ret == :ok
    # Bet was correct, player who countered should have lost a dice.
    %{hand: hand} = Player.state tooth
    assert length(hand) == 4
  end
end
