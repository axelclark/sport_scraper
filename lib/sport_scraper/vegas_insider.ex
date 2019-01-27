defmodule SportScraper.VegasInsider do
  @sports [
    "college-basketball",
    "college-football",
    "mlb",
    "nba",
    "nfl",
    "nhl"
  ]

  def get_all_odds() do
    Enum.reduce(@sports, %{}, fn sport, acc ->
      Map.put(acc, sport, get_odds(sport))
    end)
  end

  def get_odds(sport) do
    url = "http://www.vegasinsider.com/#{sport}/odds/futures/"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Floki.find(".table-wrapper.cellTextNorm td")
        |> Stream.chunk_every(2)
        |> Stream.map(&extract_name_and_odds/1)
        |> Stream.filter(&String.contains?(&1.odds, "/"))
        |> Stream.map(&format_odds/1)
        |> Enum.reduce_while([], &remove_new_category/2)
        |> Enum.reverse()

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  ## Helpers

  ## get_odds

  defp extract_name_and_odds([team_data, odds_data]) do
    {_, _, [team_name]} = team_data
    {_, _, [odds]} = odds_data

    %{odds: odds, team_name: team_name}
  end

  defp format_odds(%{odds: odds} = team) do
    odds =
      odds
      |> String.split("/")
      |> Enum.map(&String.to_integer(&1))
      |> calculate_odds()

    %{team | odds: odds}
  end

  defp calculate_odds([numerator, denominator]) do
    odds = numerator / denominator * 200
    round(odds)
  end

  defp remove_new_category(next_team, []) do
    {:cont, [next_team]}
  end

  defp remove_new_category(next_team, acc) do
    %{odds: last_team_odds} = hd(acc)
    %{odds: next_team_odds} = next_team

    case(last_team_odds <= next_team_odds) do
      true -> {:cont, [next_team] ++ acc}
      false -> {:halt, acc}
    end
  end
end
