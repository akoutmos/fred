# Fred

An Elixir client for the [FRED® (Federal Reserve Economic Data) API](https://fred.stlouisfed.org/docs/api/fred/), powered by [Req](https://hexdocs.pm/req).

FRED provides access to over 800,000 economic time series from 100+ sources including the Bureau of Labor Statistics, the Bureau of Economic Analysis, and the Federal Reserve Board.

## Installation

Add `fred` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fred, "~> 0.1.0"}
  ]
end
```

## Configuration

You'll need a free FRED API key. [Register here](https://fred.stlouisfed.org/docs/api/api_key.html).

```elixir
# config/config.exs
config :fred, api_key: "your_api_key_here"
```

Or use an environment variable:

```elixir
config :fred, api_key: System.get_env("FRED_API_KEY")
```

### Optional Settings

```elixir
config :fred,
  api_key: System.get_env("FRED_API_KEY"),
  base_url: "https://api.stlouisfed.org/fred",  # default
  recv_timeout: 30_000                           # default, in ms
```

### Optional: Geo Structs for Shape Data

If you use the GeoFRED Maps endpoints and want native Elixir geometry structs
instead of raw GeoJSON maps, add the [`geo`](https://hex.pm/packages/geo) library:

```elixir
def deps do
  [
    {:fred, "~> 0.1.0"},
    {:geo, "~> 3.6 or ~> 4.0"}   # optional — enables Fred.Geo and decode: :geo
  ]
end
```

See the [Maps / Geo Integration](#geo-integration) section below.

## Quick Start

```elixir
# Fetch the unemployment rate series metadata
{:ok, data} = Fred.Series.get("UNRATE")
series = hd(data["seriess"])
IO.puts(series["title"])
#=> "Unemployment Rate"

# Get monthly observations since 2020
{:ok, data} = Fred.Series.observations("UNRATE",
  observation_start: "2020-01-01",
  frequency: "m"
)
for obs <- data["observations"] do
  IO.puts("#{obs["date"]}: #{obs["value"]}%")
end

# Search for series about GDP
{:ok, results} = Fred.Series.search("gross domestic product",
  order_by: "popularity",
  sort_order: "desc",
  limit: 5
)
for s <- results["seriess"] do
  IO.puts("#{s["id"]}: #{s["title"]}")
end
```

## API Reference

### Categories — `Fred.Categories`

Navigate the FRED category hierarchy (root category ID is `0`).

```elixir
Fred.Categories.get(0)                           # Root category
Fred.Categories.children(0)                      # Top-level categories
Fred.Categories.related(32073)                   # Related categories
Fred.Categories.series(125, limit: 10)           # Series in a category
Fred.Categories.tags(125)                        # Tags for a category
Fred.Categories.related_tags(125, tag_names: "quarterly")
```

### Series — `Fred.Series`

The core module for accessing economic data.

```elixir
# Metadata
Fred.Series.get("GDP")
Fred.Series.categories("GDP")
Fred.Series.release("GDP")
Fred.Series.tags("GDP")
Fred.Series.vintage_dates("GDP")

# Observations (the actual data!)
Fred.Series.observations("GDP",
  observation_start: "2020-01-01",
  observation_end: "2024-12-31",
  frequency: "q",                # quarterly
  units: "pch",                  # percent change
  aggregation_method: "avg"
)

# Search
Fred.Series.search("inflation", order_by: "popularity", limit: 10)
Fred.Series.search("UNRATE", search_type: "series_id")
Fred.Series.search_tags("monetary service index")
Fred.Series.search_related_tags("mortgage rate", tag_names: "30-year;frb")

# Recently updated series
Fred.Series.updates(limit: 20, filter_value: "macro")
```

#### Observation Parameters

| Parameter            | Values                                                        | Description             |
| -------------------- | ------------------------------------------------------------- | ----------------------- |
| `units`              | `lin`, `chg`, `ch1`, `pch`, `pc1`, `pca`, `cch`, `cca`, `log` | Data transformation     |
| `frequency`          | `d`, `w`, `bw`, `m`, `q`, `sa`, `a`                           | Aggregation frequency   |
| `aggregation_method` | `avg`, `sum`, `eop`                                           | How to aggregate        |
| `output_type`        | `1`, `2`, `3`, `4`                                            | Real-time output format |

### Releases — `Fred.Releases`

Information about data publications.

```elixir
Fred.Releases.list(limit: 20)                       # All releases
Fred.Releases.dates(sort_order: "desc")              # Release dates
Fred.Releases.get(53)                                # Specific release (GDP)
Fred.Releases.release_dates(53, limit: 5)            # Dates for a release
Fred.Releases.series(50, order_by: "popularity")     # Series on a release
Fred.Releases.sources(50)                            # Sources for a release
Fred.Releases.tags(50)                               # Tags for a release
Fred.Releases.related_tags(50, tag_names: "sa")      # Related tags
Fred.Releases.tables(53)                             # Release tables
```

### Sources — `Fred.Sources`

Data providers (BLS, BEA, Federal Reserve Board, etc.).

```elixir
Fred.Sources.list()                            # All sources
Fred.Sources.get(1)                            # Board of Governors
Fred.Sources.releases(1, order_by: "name")     # Releases from a source
```

### Tags — `Fred.Tags`

Tags are attributes assigned to series for discovery and filtering.

```elixir
Fred.Tags.list(order_by: "popularity", limit: 20)  # Popular tags
Fred.Tags.list(tag_group_id: "geo")                 # Geographic tags
Fred.Tags.list(search_text: "inflation")            # Search tags
Fred.Tags.related(tag_names: "monetary aggregates;m1")
Fred.Tags.series(tag_names: "slovenia;food;oecd")
```

### Maps (GeoFRED) — `Fred.Maps`

Geographic/regional economic data and shape files.

```elixir
Fred.Maps.shapes("state")                     # US state boundaries (raw GeoJSON)
Fred.Maps.series_group("SMU56000000500000001a")
Fred.Maps.series_data("WIPCPI")
Fred.Maps.regional_data(
  series_group: "882",
  region_type: "state",
  date: "2023-01-01",
  frequency: "a"
)
```

> **⚠️ Note:** The GeoFRED shapes endpoint returns coordinates as quantized
> integers, not standard WGS84 lon/lat. These cannot be rendered directly on
> web maps. For map visualization, use standard GeoJSON boundaries (e.g. from
> the US Census Bureau) and pair them with FRED economic data via
> `regional_data/1` or `Fred.Series`.

#### Geo Integration

When the [`geo`](https://hex.pm/packages/geo) library is installed, you can
decode GeoJSON responses into native `Geo` structs (`%Geo.MultiPolygon{}`,
`%Geo.Polygon{}`, `%Geo.Point{}`, etc.):

```elixir
# Option 1: decode inline via the :decode option
{:ok, features} = Fred.Maps.shapes("state", decode: :geo)

hd(features).geometry
#=> %Geo.MultiPolygon{coordinates: [...], srid: 4326}

hd(features).properties
#=> %{"name" => "Alabama", ...}

# Option 2: decode manually with Fred.Geo
{:ok, geojson} = Fred.Maps.shapes("state")
{:ok, features} = Fred.Geo.decode(geojson)

# Extract just geometries (no properties)
{:ok, geometries} = Fred.Geo.decode_geometries(geojson)

# Encode back to GeoJSON maps
{:ok, geojson_map} = Fred.Geo.encode(hd(geometries))

# Check if geo is available at runtime
Fred.Geo.available?()  #=> true
```

The `geo` structs interoperate with the broader Elixir ecosystem:

- [`geo_postgis`](https://hex.pm/packages/geo_postgis) — Store shapes in PostGIS
- [`topo`](https://hex.pm/packages/topo) — Spatial calculations (contains, intersects, etc.)

If `geo` is not installed, the `Fred.Geo` functions return
`{:error, %Fred.Error{type: :dependency_missing}}` and the `decode: :geo`
option does the same. The rest of the library works normally.

## Error Handling

All functions return `{:ok, result}` or `{:error, %Fred.Error{}}`:

```elixir
case Fred.Series.observations("INVALID_ID") do
  {:ok, data} ->
    IO.inspect(data["observations"])

  {:error, %Fred.Error{type: :api_error, message: msg, status: status}} ->
    IO.puts("API error (#{status}): #{msg}")

  {:error, %Fred.Error{type: :transport_error, message: msg}} ->
    IO.puts("Network error: #{msg}")
end
```

You can also use the bang variant on the client:

```elixir
# Raises on error
data = Fred.Client.get!("/series/observations", series_id: "GDP")
```

## Real-Time Periods & Vintage Dates

FRED supports querying data as it was known at a specific point in time:

```elixir
# What was GDP data on Jan 1, 2015?
Fred.Series.observations("GDP",
  realtime_start: "2015-01-01",
  realtime_end: "2015-01-01"
)

# Get data at multiple vintage dates
Fred.Series.observations("GDP",
  vintage_dates: "2015-01-01,2016-01-01,2017-01-01"
)

# See when a series was revised
Fred.Series.vintage_dates("GDP")
```

## Date Parameters

Date parameters accept strings in `YYYY-MM-DD` format or Elixir `Date` structs:

```elixir
# Both work
Fred.Series.observations("UNRATE", observation_start: "2020-01-01")
Fred.Series.observations("UNRATE", observation_start: ~D[2020-01-01])
```

## Livebook Notebooks

The `notebooks/` directory contains interactive [Livebook](https://livebook.dev)
notebooks that demonstrate the library with live charts:

| Notebook                                                                     | Description                                                                           |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [`01_getting_started.livemd`](notebooks/01_getting_started.livemd)           | Series lookup, observations, search, area charts, and FRED's built-in transformations |
| [`02_comparing_indicators.livemd`](notebooks/02_comparing_indicators.livemd) | Multi-series overlays, normalized comparisons, Treasury yield curves                  |
| [`03_inflation_deep_dive.livemd`](notebooks/03_inflation_deep_dive.livemd)   | CPI vs. Core vs. PCE, category breakdowns, heatmaps, Fed response                     |
| [`04_geofred_maplibre.livemd`](notebooks/04_geofred_maplibre.livemd)         | GeoFRED shapes on MapLibre, Geo struct integration, unemployment choropleth           |

To run them, open Livebook, set the `FRED_API_KEY` environment variable, and
open any `.livemd` file. Notebooks 01–03 use [VegaLite](https://hexdocs.pm/vega_lite)
for charting; notebook 04 uses [MapLibre](https://hexdocs.pm/maplibre) for
interactive geographic maps and the [Geo](https://hexdocs.pm/geo) library for
GeoJSON struct conversion.

## Telemetry

Fred emits [`:telemetry`](https://hexdocs.pm/telemetry) spans for every API request, giving you full observability over latency, error rates, and usage patterns.

### Quick Setup — Built-in Logger

The fastest way to see what's happening is to attach the built-in logger handler. Add it to your application's `start/2`:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    Fred.Telemetry.Logger.attach()

    children = [
      # ...
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

You'll see log output like:

```
[info] [fred] GET /series/observations — 200 in 142ms (params: %{series_id: "UNRATE", frequency: "m"})
[info] [fred] GET /series — error in 83ms: (400) Bad Request (params: %{series_id: ""})
[info] [fred] GET /series/observations — exception in 5012ms: %Req.TransportError{reason: :timeout}
```

Configure the log level or use a custom handler ID:

```elixir
Fred.Telemetry.Logger.attach(level: :debug, handler_id: "my-fred-log")
```

Detach when you no longer need it:

```elixir
Fred.Telemetry.Logger.detach()
```

### Events

Every request emits a `[:fred, :request]` span with three possible events:

#### `[:fred, :request, :start]`

Emitted when a request begins.

| Measurement    | Type    | Description                 |
| -------------- | ------- | --------------------------- |
| `:system_time` | integer | System time in native units |

| Metadata    | Type   | Description                             |
| ----------- | ------ | --------------------------------------- |
| `:endpoint` | string | API path, e.g. `"/series/observations"` |
| `:base_url` | string | Base URL used                           |
| `:params`   | map    | Query params (API key redacted)         |

#### `[:fred, :request, :stop]`

Emitted when a request completes (HTTP round-trip finished).

| Measurement | Type    | Description                              |
| ----------- | ------- | ---------------------------------------- |
| `:duration` | integer | Wall-clock duration in native time units |

| Metadata    | Type              | Description                             |
| ----------- | ----------------- | --------------------------------------- |
| `:endpoint` | string            | API path                                |
| `:base_url` | string            | Base URL used                           |
| `:params`   | map               | Query params (API key redacted)         |
| `:status`   | integer \| nil    | HTTP status code                        |
| `:result`   | `:ok` \| `:error` | Whether the call succeeded              |
| `:error`    | `%Fred.Error{}`   | Only present when `:result` is `:error` |

#### `[:fred, :request, :exception]`

Emitted when the request raises an unexpected exception.

| Measurement | Type    | Description                  |
| ----------- | ------- | ---------------------------- |
| `:duration` | integer | Duration until the exception |

| Metadata      | Type   | Description                    |
| ------------- | ------ | ------------------------------ |
| `:endpoint`   | string | API path                       |
| `:kind`       | atom   | `:throw`, `:error`, or `:exit` |
| `:reason`     | term   | The exception or thrown value  |
| `:stacktrace` | list   | The stacktrace                 |

### Custom Handlers

Attach your own handler to any event:

```elixir
# Track request durations in StatsD / Prometheus / etc.
:telemetry.attach(
  "fred-metrics",
  [:fred, :request, :stop],
  fn _event, %{duration: duration}, %{endpoint: endpoint}, _config ->
    ms = System.convert_time_unit(duration, :native, :millisecond)
    MyApp.Metrics.histogram("fred.request.duration", ms, tags: [endpoint: endpoint])
  end,
  nil
)

# Alert on errors
:telemetry.attach(
  "fred-errors",
  [:fred, :request, :stop],
  fn _event, _measurements, %{result: :error, endpoint: ep, error: err}, _config ->
    MyApp.Alerting.notify("FRED API error on #{ep}: #{Exception.message(err)}")
    _event, _measurements, _metadata, _config -> :ok
  end,
  nil
)
```

### Security

The API key is **always redacted** from telemetry metadata. The `:params` map in
all events has the `:api_key` key stripped before emission, so it is safe to log
or forward to external monitoring systems.

## License

MIT
