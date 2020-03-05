defmodule ExEs do
  # exclude non-endpoint spec
  files = File.ls!("api")
          |> Enum.map(fn file -> "api/" <> file end)
          |> List.delete("api/_common.json")
  use(ExEs.Gen, %{dirs: [], files: files})
end
