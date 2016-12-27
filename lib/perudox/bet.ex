defmodule Perudox.Bet do
  @moduledoc """
  This module materializes a bet. It always contains a count and a value. This
  module allows verifying that a bet is legal or stronger than another.
  """

  alias Perudox.Bet

  @type bet_or_tuple :: Bet.t | {non_neg_integer, non_neg_integer}
  @type t :: %Bet{value: integer, count: integer}
  defstruct value: 0, count: 0

  @spec legal_count?(non_neg_integer) :: :ok | {:error, atom}
  def legal_count?(count) when count >= 1, do: :ok
  def legal_count?(_), do: {:error, :illegal_bet_count}

  @spec legal_value?(non_neg_integer) :: :ok | {:error, atom}
  def legal_value?(value) when value in 1..6, do: :ok
  def legal_value?(_), do: {:error, :illegal_bet_value}

  @spec stronger?(Perudox.Game.State.mode, bet_or_tuple, bet_or_tuple) :: :ok | {:error, atom}
  def stronger?(mode, %{count: c1, value: v1}, %{count: c2, value: v2}), do: stronger? mode, {c1, v1}, {c2, v2}
  def stronger?(_mode, {c1, v}, {c2, v}), do: okify :bet_too_weak, c1 > c2
  def stronger?(:normal, {c1, 1}, {c2, _}), do: okify :bet_too_weak, c1 > c2 * 2
  def stronger?(:normal, {c1, _}, {c2, 1}), do: okify :bet_too_weak, c1 > c2 * 2
  def stronger?(_mode, b1, b2), do: okify :bet_too_weak, b1 > b2

  @spec okify(atom, boolean) :: :ok | {:error, atom}
  defp okify(_, true), do: :ok
  defp okify(e, _), do: {:error, e}
end
