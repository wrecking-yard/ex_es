defmodule ExEs.Docs do
  def get_moduledocs() do
    "Generated Elasticsearch client"
  end
  def get_function_docs(data, function) when is_map(data) and is_bitstring(function) do
    IO.puts(function)
    function_specs = Map.get(data, function)
    Enum.map(["```"]
    ++ [function <> ":\n"]
    ++ [function_specs |> Map.get("documentation") |> Map.get("description"), ""]
    ++ ExEs.Docs.make_params_docs(["params", function_specs |> Map.get("params")], "  ")
    ++ ["```"], fn e -> e <> "\n" end) |> List.to_string()
  end
  def get_function_docs(data, {module, function}) when is_map(data) do
    IO.puts(module <> "." <> function)
    function_specs = Map.get(data, module <> "." <> function)
    Enum.map(["```"]
    ++ [function <> ":\n"]
    ++ [function_specs |> Map.get("documentation") |> Map.get("description"), ""]
    ++ ExEs.Docs.make_params_docs(["params", function_specs |> Map.get("params")], "  ")
    ++ ["```"], fn e -> e <> "\n" end) |> List.to_string()
  end
  # special case? `api/render_search_template.json` don't have `params` key,
  # despite the fact param-less function tend to have at least `"params":{}`
  def make_params_docs([name, params], indent) when is_nil(params) do
    List.flatten([
      indent <> name <> ":",
      indent <> indent <> "none"
    ])
  end
  def make_params_docs([name, params], indent) do
    List.flatten([
      indent <> name <> ":",
      for {name, properties} <- Map.to_list(params) do
        make_param_docs([name, properties], indent <> indent)
      end
    ])
  end
  def make_param_docs([name, properties], indent) do
    List.flatten([
      indent <> name <> ":",
      for {name, property} <- Map.to_list(properties) do
        make_param_property_docs([name, property], indent <> indent)
      end
      ])
  end
  def make_param_property_docs([name, property], indent) when is_bitstring(property) do
    [indent <> name <> ": " <> property]
  end
  def make_param_property_docs([name, property], indent) when is_integer(property) do
    [indent <> name <> ": " <> Integer.to_string(property)]
  end
  def make_param_property_docs([name, property], indent) when is_boolean(property) do
    [indent <> name <> ": " <> to_string(property)]
  end
  def make_param_property_docs([name, property], indent) when is_nil(property) do
    [indent <> name <> ": " <> "none"]
  end
  def make_param_property_docs([name, property], indent) when is_list(property) do
    [indent <> name <> ":"] ++ Enum.map(property, fn e -> indent <> indent <> e end)
  end
  def indent(indent_level) do
    for _ <- 1..indent_level do
      " "
    end |> List.to_string()
  end
end
