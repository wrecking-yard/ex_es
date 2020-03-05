defmodule ExEsTest do
  use ExUnit.Case
  doctest ExEs

  test "greets the world" do
    assert ExEs.hello() == :world
  end
end
