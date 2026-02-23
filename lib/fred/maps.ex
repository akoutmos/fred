defmodule Fred.Maps do
  @moduledoc """
  Functions for the FRED Maps (GeoFRED) API endpoints.

  The GeoFRED API provides access to geographic/regional economic data and shape
  files. Not all FRED series have geographic data available. The shapes endpoint
  specifically returns GeoJSON which can then be parsed by the `Geo` library to
  be turned into `Geo` structs.

  ## Endpoints

    - `shapes/1` — [`/geofred/shapes/file`](https://fred.stlouisfed.org/docs/api/geofred/shapes.html)
    - `series_group/1` — [`/geofred/series/group`](https://fred.stlouisfed.org/docs/api/geofred/series_group.html)
    - `series_data/2` — [`/geofred/series/data`](https://fred.stlouisfed.org/docs/api/geofred/series_data.html)
    - `regional_data/4` — [`/geofred/regional/data`](https://fred.stlouisfed.org/docs/api/geofred/regional_data.html)

  > #### Coordinate System {: .info}
  >
  > The GeoFRED shapes endpoint returns coordinates
  > as quantized integers, not standard WGS84 longitude/latitude. These shapes
  > cannot be rendered directly on web maps (MapLibre, Leaflet, etc.) without
  > dequantization. For map rendering, use standard GeoJSON boundary files from
  > sources like the US Census Bureau and use `Fred.Maps.regional_data/4` or
  > `Fred.Series` for the economic data.
  """

  alias Fred.Client
  alias Fred.Utils

  @series_data_schema Utils.generate_schema([
                        {:date, :date, "The observation date."},
                        {:date, :start_date, "Start of date range."}
                      ])

  @doc """
  Get shape files for a geographic type. Returns GeoJSON data for the
  specified shape type.

  The `shape` argument must be one of the following values:

  - `:bea` - Bureau of Economic Anaylis Region
  - `:msa` - Metropolitan Statistical Area
  - `:frb` - Federal Reserve Bank Districts
  - `:necta` - New England City and Town Area
  - `:state`
  - `:country`
  - `:county` - USA Counties
  - `:censusregion` - US Census Regions
  - `:censusdivision` - US Census Divisons

  ## Examples

      iex> {:ok, geojson} = Fred.Maps.shapes("state")
      iex> %Geo.GeometryCollection{geometries: [_ | _]} = geojson
  """
  @spec shapes(shape :: String.t()) :: {:ok, map() | list()} | {:error, Fred.Error.t()}
  def shapes(shape) do
    case Client.get_map_raw("/shapes/file", shape: shape) do
      {:ok, body} ->
        Geo.JSON.decode(body)

      error ->
        error
    end
  end

  @doc """
  Get the series group information for a regional data series.

  ## Examples

      iex> {:ok, series_group} = Fred.Maps.series_group("SMU56000000500000001a")
      iex> %{"series_group" => _series_group} = series_group
  """
  @spec series_group(series_id :: String.t()) :: Client.response()
  def series_group(series_id) do
    Client.get_map_json("/series/group", series_id: series_id)
  end

  @doc """
  Get series data for a geographic region.

  ## Options

    #{NimbleOptions.docs(@series_data_schema)}

  ## Examples

      iex> {:ok, _wisconsin_cpi} = Fred.Maps.series_data("WIPCPI")

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Maps.series_data("WIPCPI", date: "Bad Input")
  """
  @spec series_data(series_id :: String.t(), opts :: keyword()) :: Client.response()
  def series_data(series_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @series_data_schema) do
      params = Keyword.put(opts, :series_id, series_id)
      Client.get_map_json("/series/data", params)
    end
  end

  @regional_data_schema Utils.generate_schema([
                          :frequency,
                          :units,
                          :season,
                          :transformation,
                          :aggregation_method,
                          {:date, :start_date, "Start of date range."}
                        ])

  @doc """
  Get regional economic data by series group.

  The `region_type` argument must be one of:

  - `:bea`
  - `:msa`
  - `:frb`
  - `:necta`
  - `:state`
  - `:country`
  - `:county`
  - `:censusregion`

  ## Options

    #{NimbleOptions.docs(@regional_data_schema)}

  ## Examples

      iex> {:ok, _} =
      ...>   Fred.Maps.regional_data(
      ...>     "882",
      ...>     :state,
      ...>     ~D[2023-01-01],
      ...>     frequency: :a,
      ...>     units: :lin,
      ...>     season: :NSA
      ...>   )

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Maps.regional_data("882", :state, ~D[2023-01-01], units: "Bad Input")
  """
  @spec regional_data(series_group :: String.t(), region_type :: String.t(), date :: Date.t(), keyword()) ::
          Client.response()
  def regional_data(series_group, region_type, date, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @regional_data_schema) do
      opts =
        opts
        |> Keyword.put(:series_group, series_group)
        |> Keyword.put(:region_type, region_type)
        |> Keyword.put(:date, date)

      Client.get_map_json("/regional/data", opts)
    end
  end
end
