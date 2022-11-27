defmodule NervesRpi4Test do
  use ExUnit.Case
  doctest NervesRpi4

  test "greets the world" do
    assert NervesRpi4.hello() == :world
  end
end
