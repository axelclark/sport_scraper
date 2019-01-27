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
      Map.put(acc, format_sport(sport), get_odds(sport))
    end)
  end

  def get_odds(sport) do
    url = "http://www.vegasinsider.com/#{sport}/odds/futures/"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Floki.find(".table-wrapper.cellTextNorm td")
        |> Stream.chunk_every(2)
        |> Stream.map(&extract_name_and_odds(&1, sport))
        |> Stream.filter(&String.contains?(&1.odds, "/"))
        |> Stream.map(&format_moneyline/1)
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

  defp format_sport("college-basketball"), do: "CBB"
  defp format_sport("college-football"), do: "CFB"
  defp format_sport("mlb"), do: "MLB"
  defp format_sport("nba"), do: "NBA"
  defp format_sport("nfl"), do: "NFL"
  defp format_sport("nhl"), do: "NHL"
  defp format_sport(name), do: name

  defp extract_name_and_odds([team_data, odds_data], sport) do
    {_, _, [team_name]} = team_data
    {_, _, [odds]} = odds_data

    %{odds: odds, team_name: team_name, sports_league: format_sport(sport)}
  end

  defp format_moneyline(%{odds: odds} = team) do
    odds =
      odds
      |> String.split("/")
      |> Enum.map(&String.to_integer(&1))
      |> convert_fractional_to_moneyline()

    %{team | odds: odds}
  end

  defp convert_fractional_to_moneyline([numerator, denominator])
       when numerator / denominator > 1 do
    odds = numerator / denominator * 100
    round(odds)
  end

  defp convert_fractional_to_moneyline([numerator, denominator])
       when numerator / denominator <= 1 do
    odds = denominator / numerator * -100
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
