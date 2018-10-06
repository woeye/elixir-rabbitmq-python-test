defmodule RmqtestTest do
  use ExUnit.Case
  doctest Rmqtest

  test "greets the world" do
    assert Rmqtest.hello() == :world
  end
end
