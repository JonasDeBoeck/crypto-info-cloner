defmodule ClonerWorkerTest do
  use ExUnit.Case
  doctest ClonerWorker

  test "greets the world" do
    assert ClonerWorker.hello() == :world
  end
end
