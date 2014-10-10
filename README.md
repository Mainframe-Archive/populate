# Populate

The `Populate` module provides a lightweight tool for creating a set of
things from a builder and corresponding description. Basically,
simple fixtures.

## Usage

A basic example:

```elixir
defmodule CritterTest
  use ExUnit.Case

  defmodule Critters do
    use Populate

    def create(:frog, opts),   do: :frog
    def create(:lizard, opts), do: :lizard
  end

  setup context do
    {:ok, Critters.populate(context[:populace])}
  end

  @tag populace: [:frog, lizards: [count: 2, key: :lizard]]
  test "the populace", %{populace: %{frog: frog, lizards: lizards}} do
    assert frog == :frog
    assert length(lizards) == 2
    for lizard <- lizards, do: assert lizard == :lizard
  end
end
```

Check out `PopulateTest` for a more complex example showing some of
the available configuration.
