defmodule SportScraper do
  def get_vegas_insider_odds() do
    content = SportScraper.VegasInsider.get_all_odds()

    SportScraper.Export.write_csv(content, "vegas_insider")
  end
end
