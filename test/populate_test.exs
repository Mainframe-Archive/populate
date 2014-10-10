defmodule PopulateTest do
  use ExUnit.Case
  alias Populate.Utils

  defmodule EnvironmentBuilder do
    use Populate

    def create(:pond, _opts),              do: :pond
    def create(:tadpole, %{mutant: true}), do: {:tadpole, {:mutant, Utils.rando}}
    def create(:tadpole, _opts) ,          do: {:tadpole, :normal}
    def create(:frog, %{pond: pond, tadpoles: tadpoles}) do
      {:frog, %{pond: pond, tadpoles: tadpoles}}
    end
  end

  setup context do
    Utils.reseed
    {:ok, EnvironmentBuilder.populate(context[:populace])}
  end

  @tag populace: [:pond]
  test "as simple as it gets, one thing", %{pond: pond} do
    assert pond == :pond
  end

  @tag populace: [tadpole: 2]
  test "create more than one of a thing", %{tadpole: tadpoles} do
    assert length(tadpoles) == 2
    for tadpole <- tadpoles, do: assert tadpole == {:tadpole, :normal}
  end

  @tag populace: [frogs: [key: :frog,
                          count: 2,
                          each: [tadpoles: [key: :tadpole,
                                            count: 5,
                                            mutant: true]],
                          all: [:pond]]]
  test "the all populace", %{frogs: frogs} do
    assert length(frogs) == 2
    [{:frog, %{tadpoles: tadpoles1}}, {:frog, %{tadpoles: tadpoles2}}] = frogs
    assert tadpoles1 != tadpoles2

    for {:frog, %{pond: pond, tadpoles: tadpoles}} <- frogs do
      assert pond == :pond
      for tadpole <- tadpoles, do: assert {:tadpole, {:mutant, _}} = tadpole
    end
  end

end
