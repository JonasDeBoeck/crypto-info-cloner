defmodule DirectorTest do
  use ExUnit.Case
  doctest Director

  test "greets the world" do
    assert Director.hello() == :world
  end
end
