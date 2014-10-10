defmodule Populate.Utils do
  @moduledoc """
  Utilities for the populate library.
  """

  @doc """
  Set the random number generators seed.

  NB: This is fixed between erlang VM runs -- for different random values,
  this must be called.
  """
  def reseed(seed \\ :erlang.now) do
    :random.seed(seed)
  end

  @doc """
  Create a random string of the provided length, from the list of chars
  provided.

  NB: for a new sequence of random strings, `random_seed/0` must be called
  first
  """
  def rando(length \\ 10, range \\ Enum.into(48..122, []), acc \\ [])
  def rando(0, _, acc) do
    :erlang.list_to_binary(acc)
  end
  def rando(length, range, acc) do
    n = length(range) |> :random.uniform
    rando(length - 1, range, [Enum.at(range, n - 1) | acc])
  end
end
