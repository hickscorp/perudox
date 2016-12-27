defmodule Perudox.BetTest do
  @moduledoc """
  """
  use ExUnit.Case
  doctest Perudox

  alias Perudox.Bet

  @count_tests [{-3..0, false}, {1..50, true}]
  @value_tests [{-5..0, false}, {1..6, true}, {7..12, false}]
  @bet_tests [
    {:normal, {10, 1}, {10, 1}, false, "with an identical bet"},
    {:normal, {20, 1}, {10, 2}, false, "by moving to aces without enough count"},
    {:normal, {21, 1}, {10, 2}, true, "by moving to aces with enough count"},
    {:normal, {11, 2}, {10, 1}, false, "by moving from aces without enough count"},
    {:normal, {21, 2}, {10, 1}, true, "by moving from aces with enough count"},
    {:normal, {11, 1}, {10, 1}, true, "on more aces"},
    {:normal, {10, 1}, {11, 1}, false, "on less aces"},
    {:normal, {11, 2}, {10, 2}, true, "on same value with enough count"},
  ]

  test "knows legal and illegal counts" do
    assert Enum.all? @count_tests, fn {rng, exp} ->
      Enum.all? rng, fn val -> exp == (:ok == Bet.legal_count? val) end
    end
  end

  test "knows legal and illegal values" do
    assert Enum.all? @value_tests, fn {rng, exp} ->
      Enum.all? rng, fn val -> exp == (:ok == Bet.legal_value? val) end
    end
  end

  describe "betting" do
    Enum.each @bet_tests, fn {mode, b1, b2, exp, msg} ->
      test msg do
        val = :ok == Bet.stronger? unquote(mode), unquote(b1), unquote(b2)
        assert val == unquote exp
      end
    end
  end
end
