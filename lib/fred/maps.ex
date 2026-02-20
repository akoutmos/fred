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

  @base_url "https://api.stlouisfed.org/geofred"

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
    {decode, opts} = Keyword.pop(opts, :decode)
    params = build_params(opts, shape: shape)

    with {:ok, body} <-
           Fred.Client.get_raw(
             "#{@base_url}/shapes/file",
             params,
             "/geofred/shapes/file",
             @base_url
           ) do
      case decode do
        :geo -> Fred.Geo.decode(body)
        _ -> {:ok, body}
      end
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
  @spec series_group(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def series_group(series_id, opts \\ []) do
    params = build_params(opts, series_id: series_id, file_type: "json")
    Fred.Client.get_raw("#{@base_url}/series/group", params, "/geofred/series/group", @base_url)
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
  @spec series_data(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def series_data(series_id, opts \\ []) do
    params = build_params(opts, series_id: series_id, file_type: "json")
    Fred.Client.get_raw("#{@base_url}/series/data", params, "/geofred/series/data", @base_url)
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
        frequency: "a"
      )
  """
  @spec regional_data(keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def regional_data(opts \\ []) do
    params = build_params(opts, file_type: "json")
    Fred.Client.get_raw("#{@base_url}/regional/data", params, "/geofred/regional/data", @base_url)
  end

  # Build a params map with the api_key injected and optional extra defaults merged in.
  defp build_params(opts, defaults) do
    defaults
    |> Keyword.merge(opts)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
    |> Map.put(:api_key, Fred.api_key())
  end
end
