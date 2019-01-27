defmodule SportScraperTest do
  use ExUnit.Case
  doctest SportScraper

  test "greets the world" do
    assert SportScraper.hello() == :world
  end
end
