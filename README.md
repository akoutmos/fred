<!--START-->
<p align="center">
  <img align="center" width="50%" src="guides/images/logo.png" alt="Fred Logo">
</p>

<p align="center">
  An Elixir client for the <a href="https://fred.stlouisfed.org/docs/api/fred/">FRED® (Federal Reserve Economic Data) API</a>,
  powered by <a href="https://hexdocs.pm/req">Req</a>.
</p>

<p align="center">
  <a href="https://hex.pm/packages/fred">
    <img alt="Hex.pm" src="https://img.shields.io/hexpm/v/fred?style=for-the-badge">
  </a>

  <a href="https://github.com/akoutmos/fred/actions">
    <img alt="GitHub Workflow Status (master)" src="https://img.shields.io/github/actions/workflow/status/akoutmos/fred/main.yml?label=Build%20Status&style=for-the-badge&branch=master">
  </a>

  <a href="https://coveralls.io/github/akoutmos/fred?branch=master">
    <img alt="Coveralls master branch" src="https://img.shields.io/coveralls/github/akoutmos/fred/master?style=for-the-badge">
  </a>

  <a href="https://github.com/sponsors/akoutmos">
    <img alt="Support Fred" src="https://img.shields.io/badge/Support%20Fred-%E2%9D%A4-lightblue?style=for-the-badge">
  </a>
</p>

<br>
<!--END-->

FRED® (Federal Reserve Economic Data) provides access to over 800,000 economic time series from 100+ sources including the Bureau of Labor
Statistics, the Bureau of Economic Analysis, and the Federal Reserve Board. This library was written to allow readers of
[Financial Analytics Using Elixir](https://financialanalytics.dev) to collect, analyze and visualize economic data from
Fred, but it is a complete Fred API client and can be used outside the context of the book.

To learn how you can analyze and visualize the financial markets using Livebook, Explorer, Scholar and Nx, be sure to pick up
a copy of our book:

<a href="https://financialanalytics.dev">
  <img align="center" width="50%" src="guides/images/book_cover.png" alt="Financial Analytics Using Elixir book cover" style="margin-left:25%">
</a>

# Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [API Coverage](#api-coverage)

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
config :fred, api_key: System.fetch_env!("FRED_API_KEY")
```

### Optional Settings

```elixir
config :fred,
  api_key: System.fetch_env!("FRED_API_KEY"),
  recv_timeout: 30_000                    # HTTP client timeout
```

## Quick Start

Once you have the Fred library added to your `mix.exs` file, obtained a Fred API key and added the necessary
configuration, you can start your project with `FRED_API_KEY=YOUR_KEY_GOES_HERE iex -S mix` and run queries
like so:

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

## API Coverage

This library allows you to access all the endpoints from the [Fred V1 API](https://fred.stlouisfed.org/docs/api/fred/).
Each group of Fred API endpoints is handled by the following library modules:

- `Fred.Categories` - Get data on Fred data categories
- `Fred.Releases` - Get data on Fred data releases
- `Fred.Series` - Get data (time series data) on actual economic observations
- `Fred.Sources` - Get the sources of the Fred data
- `Fred.Tags` - Get the tags associated with economic data
- `Fred.Maps` - Get regional data and shape files from Fred

Be sure to check out each individual module to see the options available for each endpoint.

## Livebook Notebooks

The `livebooks/` directory contains interactive [Livebook](https://livebook.dev)
notebooks that demonstrate the library with live charts:

| Notebook                                                                     | Description                                                                           |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| [`1_getting_started.livemd`](./livebooks/1_getting_started.livemd)           | Series lookup, observations, search, area charts, and FRED's built-in transformations |
| [`2_comparing_indicators.livemd`](./livebooks/2_comparing_indicators.livemd) | Multi-series overlays, normalized comparisons, Treasury yield curves                  |
| [`3_inflation_deep_dive.livemd`](./livebooks/3_inflation_deep_dive.livemd)   | CPI vs. Core vs. PCE, category breakdowns, heatmaps, Fed response                     |
| [`4_geofred_maplibre.livemd`](./livebooks/4_geo_fred_maplibre.livemd)        | GeoFRED shapes on MapLibre, Geo struct integration, unemployment choropleth           |

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
