defmodule ExEs.Gen do
  defmacro __using__(options) do
    quote(bind_quoted: [options: options]) do
      Module.put_attribute(__MODULE__, :moduledoc, {0, ExEs.Docs.get_moduledocs()})
      # TODO: * listing of the directory is not preserving file path
      #       * listing of the directory can contain non-files
      specs = Enum.map(options.dirs, fn dir -> Enum.map(File.ls!(dir), fn file -> file end) end)
              |> List.flatten(options.files)
              |> ExEs.Gen.get_data()
              |> Enum.reduce(
                %{}, fn x, acc -> Map.merge(x, acc) end
              )
      names_grouped = ExEs.Gen.group(specs)

      # generate top level functions
      for function <- Map.get(names_grouped, "rest") do
        #Module.put_attribute(__MODULE__, :doc, {0, ExEs.Docs.get_function_docs(specs, function)})
        @doc ExEs.Docs.get_function_docs(specs, function)
        def unquote(String.to_atom(function))(unquote(ExEs.Gen.make_params(__MODULE__))) do
          nil
        end
      end
      # remove what's processed
      names_grouped = Map.delete(names_grouped, "rest")
      # * generate nested modules and their functions
      # * `for` returns, which is not necessary here. could be that `Enum.each` would be
      #   better here?
      # * this won't traverse Map recursively, now it's not needed though.
      for {module, functions} <- Map.to_list(names_grouped) do
        defmodule Module.concat(__MODULE__, String.capitalize(module)) do
          Module.put_attribute(__MODULE__, :moduledoc, {0, ExEs.Docs.get_moduledocs()})
          for function <- functions do
            Module.put_attribute(__MODULE__, :doc, {0, ExEs.Docs.get_function_docs(specs, {module, function})})
            def unquote(String.to_atom(function))(unquote(ExEs.Gen.make_params(__MODULE__))) do
              String.to_atom(unquote(function))
            end
          end
        end
      end
    end
  end

  # TODO: a lot of duplication in those functions
  def get_params(data, function) when is_map(data) and is_bitstring(function) do
    Map.get(data, function)
    |> Map.get("params")
  end
  def get_params(data, {module, function}) when is_map(data) do
    Map.get(data, module <> "." <> function)
    |> Map.get("params")
  end
  # i am not sure if param names have any meaning here, i assume they don't. what
  # matters are arity, `@docs` and types in `@spec`?
  ## they do: `h` on function, in `iex` will display arg names in header of the displayed section, and
  ## those don't originate from `@docs` or `@spec`.
  def make_params(keys, module) do
    # do I like this syntax more?
    keys
    |> Enum.map(
      fn k ->
        k
        |> String.to_atom()
        |> Macro.var(module)
      end
    )
  end
  def make_params(module) do
    Macro.var(:param_list, module)
  end
  def get_data(input) do
      Enum.map(input, fn file -> File.read!(file) |> Poison.decode!() end)
  end
  def group(input) when is_map(input) do
    Map.keys(input)
    |> Enum.group_by(
      &(
       # TODO: there needs to be nicer way, than calling two-headed function defined outside and not useful for anything else?
       String.split(&1, ".")
       |> get_key()
      ),
      &(String.split(&1, ".") |> List.last())
    )
  end
  def get_key(list) when length(list) == 1 do
   "rest"
  end
  def get_key(list) when length(list) > 1 do
    List.first(list)
  end
  def proxy(function, param_list) do
    adapter(:http_client, {function, param_list})
  end
  def adapter(http_client, {facade_function, param_list}) do
    nil
  end
end
