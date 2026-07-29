defmodule Fred.SourcesTest do
  use ExUnit.Case

  alias Explorer.DataFrame

  doctest Fred.Sources

  describe "observations_as_data_frame/2" do
    test "should properly rename columns" do
      data_frame =
        Fred.Series.observations_as_data_frame(["GDP", "UNRATE"],
          observation_start: ~D[2020-01-01],
          frequency: :q,
          units: :pch,
          rename: %{"GDP" => "gross_domestic_product", "UNRATE" => "unemployment_rate"}
        )

      assert data_frame
             |> DataFrame.names()
             |> Enum.sort() == ["date", "gross_domestic_product", "unemployment_rate"]
    end
  end
end
