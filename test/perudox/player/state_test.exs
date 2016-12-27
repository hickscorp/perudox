defmodule Perudox.Player.StateTest do
  @moduledoc """
  """
  use ExUnit.Case, async: true
  doctest Perudox.Player.State

  alias Perudox.Player.State

  @nickname "Doodloo"
  @unique_hand [1, 2, 3, 4, 7]

  setup do
    state = %State{nickname: @nickname, hand: @unique_hand}
    {:ok, %{state: state}}
  end

  test "creating by calling new succeeds", %{state: state} do
    %State{nickname: nickname} = state
    assert nickname == @nickname
  end

  test "rolling should change the hand", %{state: %{hand: hand} = state} do
    %{hand: new_hand} = state |> State.roll
    assert new_hand != hand
  end

  describe "winning a dice" do
    test "should add a dice to the hand", %{state: state} do
      %{hand: new_hand} = %{state | hand: [1, 2, 3]} |> State.win_a_dice
      assert length(new_hand) == 4
    end

    test "should error when the player is out or when the hand was empty", %{state: state} do
      ret = %{state | hand: [1], game_over: true} |> State.win_a_dice
      assert ret == {:error, :player_already_out}
      ret = %{state | hand: []} |> State.win_a_dice
      assert ret == {:error, :player_already_out}
    end

    test "should not add a dice when hand is maxed out", %{state: state} do
      ret = state |> State.win_a_dice
      assert ret == {:error, :hand_maxed_out}
    end
  end

  describe "loosing a dice" do
    test "should decrease the number of dice in hand", %{state: state} do
      %{hand: hand, game_over: over} = state |> State.lose_a_dice
      assert over == false
      assert length(hand) == 4
    end

    test "should error when the player is out or the hand is empty", %{state: state} do
      ret = %{state | hand: [1], game_over: true} |> State.lose_a_dice
      assert ret == {:error, :player_already_out}
      ret = %{state | hand: []} |> State.lose_a_dice
      assert ret == {:error, :player_already_out}
    end

    test "should mark game over if it was the last one", %{state: state} do
      %{hand: hand, game_over: over} = %{state | hand: [1]} |> State.lose_a_dice
      assert length(hand) == 0
      assert over == true
    end
  end
end
