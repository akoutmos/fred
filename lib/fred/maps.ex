defmodule Fred.Maps do
  @moduledoc """
  Functions for the FRED Maps (GeoFRED) API endpoints.

  The GeoFRED API provides access to geographic/regional economic data and shape
  files. Not all FRED series have geographic data available.

  ## Endpoints

    - `shapes/2` — Get shape files for a geographic type
    - `series_group/2` — Get series group metadata
    - `series_data/2` — Get series data for a geographic region
    - `regional_data/2` — Get regional data for a series group

  ## Geo Integration

  The shapes endpoint returns GeoJSON. If you have the
  [`geo`](https://hex.pm/packages/geo) library installed, you can decode the
  response into native `Geo` structs by passing `decode: :geo`:

      {:ok, features} = Fred.Maps.shapes("state", decode: :geo)
      hd(features).geometry
      #=> %Geo.MultiPolygon{coordinates: [...], srid: 4326}

  See `Fred.Geo` for more conversion utilities.

  > #### Coordinate System {: .warning}
  >
  > The GeoFRED shapes endpoint returns coordinates
  > as quantized integers, not standard WGS84 longitude/latitude. These shapes
  > cannot be rendered directly on web maps (MapLibre, Leaflet, etc.) without
  > dequantization. For map rendering, use standard GeoJSON boundary files from
  > sources like the US Census Bureau and use `Fred.Maps.regional_data/1` or
  > `Fred.Series` for the economic data.

  ## Examples

      # Get shape files for US states
      Fred.Maps.shapes("state")

      # Get regional unemployment data
      Fred.Maps.regional_data(
        series_group: "882",
        region_type: "state",
        date: "2023-01-01",
        frequency: "a"
      )
  """

  alias Fred.Client

  @doc """
  Get shape files for a geographic type.

  Returns GeoJSON data for the specified shape type. When the `geo` library is
  installed, you can pass `decode: :geo` to automatically convert the response
  into `Geo` structs.

  ## Parameters

    - `shape` — The shape type. One of: `"bea"`, `"msa"`, `"frb"`, `"necta"`,
      `"state"`, `"country"`, `"county"`, `"censusregion"`, `"censusdivision"`
    - `opts` — Optional parameters:
      - `:decode` — Set to `:geo` to decode the GeoJSON response into `Geo`
        structs (requires the `geo` package). Default: `nil` (returns raw maps)

  ## Examples

      # Raw GeoJSON maps (no extra dependency needed)
      {:ok, geojson} = Fred.Maps.shapes("state")
      geojson["features"] |> length()

      # Decoded into Geo structs (requires {:geo, "~> 4.0"})
      {:ok, features} = Fred.Maps.shapes("state", decode: :geo)
      hd(features).geometry
      #=> %Geo.MultiPolygon{coordinates: [...], srid: 4326}
  """
  @spec shapes(String.t(), keyword()) ::
          {:ok, map() | list()} | {:error, Fred.Error.t()}
  def shapes(shape, opts \\ []) do
    params = Keyword.put(opts, :shape, shape)

    case Client.get_map_raw("/shapes/file", params) do
      {:ok, body} ->
        Geo.JSON.decode(body)

      error ->
        error
    end
  end

  @doc """
  Get the series group information for a regional data series.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters (none currently defined)

  ## Example

      Fred.Maps.series_group("SMU56000000500000001a")
  """
  @spec series_group(String.t(), keyword()) :: Client.response()
  def series_group(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_map_json("/series/group", params)
  end

  @doc """
  Get series data for a geographic region.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters:
      - `:date` — The observation date (YYYY-MM-DD)
      - `:start_date` — Start of date range (YYYY-MM-DD)

  ## Example

      Fred.Maps.series_data("WIPCPI")
  """
  @spec series_data(String.t(), keyword()) :: Client.response()
  def series_data(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_map_json("/series/data", params)
  end

  @doc """
  Get regional economic data by series group.

  ## Parameters

    - `opts` — Required and optional parameters:
      - `:series_group` — **Required.** The series group ID string
      - `:region_type` — **Required.** One of: `"bea"`, `"msa"`, `"frb"`,
        `"necta"`, `"state"`, `"country"`, `"county"`, `"censusregion"`,
        `"censusdivision"`
      - `:date` — **Required.** The observation date (YYYY-MM-DD)
      - `:frequency` — Frequency filter
      - `:units` — Units filter (`"lin"`, `"chg"`, `"pch"`, etc.)
      - `:season` — Seasonal adjustment filter (`"SA"`, `"NSA"`, `"SSA"`)
      - `:start_date` — Start of date range (YYYY-MM-DD)
      - `:transformation` — Data transformation

  ## Example

      Fred.Maps.regional_data(
        series_group: "882",
        region_type: "state",
        date: "2023-01-01",
        frequency: "a",
        units: "lin",
        season: "NSA"
      )
  """
  @spec regional_data(keyword()) :: Client.response()
  def regional_data(opts \\ []) do
    Client.get_map_json("/regional/data", opts)
  end
end
