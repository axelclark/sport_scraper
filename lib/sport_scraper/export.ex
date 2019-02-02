defmodule SportScraper.Export do
  alias NimbleCSV.RFC4180, as: CSV

  @headers ["TeamName", "SportsLeague", "Odds"]

  def write_csv(players, site) do
    date = Date.utc_today()
    file = "output/#{date.year}-#{date.month}-#{date.day}_odds_for_#{site}.csv"

    content =
      players
      |> Enum.flat_map(fn {_sport, teams} -> teams end)
      |> Enum.map(fn team -> [team.team_name, team.sports_league, team.odds] end)
      |> add_headers()
      |> CSV.dump_to_iodata()

    File.write!(file, content)
  end

  ## Helpers

  ## write_csv

  defp add_headers(teams), do: [@headers | teams]
end
