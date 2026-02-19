defmodule FredTest do
  use ExUnit.Case
  doctest Fred

  test "greets the world" do
    assert Fred.hello() == :world
  end
end
