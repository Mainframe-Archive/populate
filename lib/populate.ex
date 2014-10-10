defmodule Populate do
  @moduledoc """
  The `Populate` module provides helpers for creating a builder
  interface which can be used with population specs.

  ## Usage

      defmodule Builder do
        use Populate

        def create(:frog, _opts),   do: :frog
        def create(:lizard, _opts), do: :lizard
      end

      schema = [frog: 2, :lizard]
      %{frog: [:frog, :frog], lizard: lizard} = Builder.populate(schema)
  """
  require Logger

  @type type :: Atom.t
  @type item :: type
             | {type, Integer.t}
             | {type, Dict.t}
  @type schema :: [item]
  @type mod_fun :: Atom.t             # module, function assumed to be `create`
                 | {Atom.t | Atom.t}  # module and function


  defmodule Interface do
    @moduledoc """
    The interface for a population builder.
    """
    use Behaviour

    @doc """
    Create the given item.
    """
    defcallback create(item :: Atom.t, opts :: Dict.t) ::
      {:ok, any} | {:error, any}
  end

  defmacro __using__(_env) do
    quote do
      @behaviour Populate.Interface

      @spec populate(Populate.schema) :: Dict.t
      def populate(populace) do
        Populate.populate(populace, __MODULE__)
      end
    end
  end


  @doc """
  Using the schema and builder create function, build the population.
  """
  @spec populate(schema, mod_fun) :: Dict.t
  def populate(schema, mod) when is_atom(mod) do
    populate(schema, {mod, :create})
  end

  def populate(schema, mod_fun) when is_tuple(mod_fun) do
    populate(schema, mod_fun, [])
  end


  @doc false
  @spec populate(schema, mod_fun, Keyword.t) :: Dict.t
  defp populate([], _, acc), do: Enum.into(acc, %{})

  defp populate([type | rest], mod_fun, acc) when is_atom(type) do
    # Handle the type being specified without options
    populate([{type, []} | rest], mod_fun, acc)
  end

  defp populate([{type, count} | rest], mod_fun, acc) when is_integer(count) do
    # Handle the count being passed in as a bare integer
    populate([{type, [count: count]} | rest], mod_fun, acc)
  end

  defp populate([{type, opts} | rest], {mod, fun} = mod_fun, acc) do
    {%{key: key, count: count, all: all, each: each}, opts} =
    extract_opts(type, opts)

    # If the all spec is passed in, populate it and merge it with the
    # create options
    opts = Dict.merge(opts, populate(all, mod_fun))

    items = fn ->
              opts = Dict.merge(opts, populate(each, mod_fun))
              apply(mod, fun, [key, Enum.into(opts, %{})])
            end
      |> Stream.repeatedly
      |> Enum.take(count)

    # If there is only 1 item (count == 1), unwrap it from the list
    items = if length(items) == 1, do: hd(items), else: items
    populate(rest, mod_fun, [{type, items} | acc])
  end


  @doc false
  @spec extract_opts(Populate.type, Dict.t) :: {Dict.t, Dict.t}
  defp extract_opts(type, opts) do
    # Extract and return options
    {key, opts}   = Dict.pop(opts, :key, type)
    {count, opts} = Dict.pop(opts, :count, 1)
    {all, opts}   = Dict.pop(opts, :all, [])
    {each, opts}  = Dict.pop(opts, :each, [])
    {%{key: key, count: count, all: all, each: each}, opts}
  end

end
