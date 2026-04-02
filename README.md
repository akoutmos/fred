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
[Financial Analytics Using Elixir](https://www.financialelixir.dev/) to collect, analyze and visualize economic data from
Fred, but it is a complete Fred API client and can be used outside the context of the book.

To learn how you can analyze and visualize the financial markets using Livebook, Explorer, Scholar and Nx, be sure to pick up
a copy of our book:

<p align="center">
  <a href="https://www.financialelixir.dev/">
    <img width="50%" src="guides/images/book_cover.png" alt="Financial Analytics Using Elixir book cover">
  </a>
</p>

# Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Quick Start](#quick-start)
- [API Coverage](#api-coverage)
- [Livebook Notebooks](#livebook-notebooks)
- [Telemetry](#telemetry)

## Installation

Add `fred` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:fred, "~> 0.2.0"}
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
iex(1)> ["GDP", "UNRATE", "CPIAUCSL"] |>
...(1)> Fred.Series.observations_as_data_frame(frequency: :a) |>
...(1)> Explorer.DataFrame.print(limit: 10, limit_dots: :bottom)
+---------------------------------------------------------------------+
|             Explorer DataFrame: [rows: 79, columns: 4]              |
+------------+------------------+------------------+------------------+
|    date    |     CPIAUCSL     |      UNRATE      |       GDP        |
|   <date>   | <decimal[38, 3]> | <decimal[38, 3]> | <decimal[38, 3]> |
+============+==================+==================+==================+
| 1947-01-01 | 22.332           | nil              | 249.616          |
| 1948-01-01 | 24.045           | 3.800            | 274.468          |
| 1949-01-01 | 23.809           | 6.100            | 272.475          |
| 1950-01-01 | 24.063           | 5.200            | 299.827          |
| 1951-01-01 | 25.973           | 3.300            | 346.913          |
| 1952-01-01 | 26.567           | 3.000            | 367.341          |
| 1953-01-01 | 26.768           | 2.900            | 389.218          |
| 1954-01-01 | 26.865           | 5.600            | 390.549          |
| 1955-01-01 | 26.796           | 4.400            | 425.480          |
| 1956-01-01 | 27.191           | 4.100            | 449.353          |
| …          | …                | …                | …                |
+------------+------------------+------------------+------------------+

:ok
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
| [`3_geofred_maplibre.livemd`](./livebooks/3_geo_fred_maplibre.livemd)        | GeoFRED shapes on MapLibre, Geo struct integration, unemployment choropleth           |

To run them, open Livebook, set the `FRED_API_KEY` environment variable, and
open any `.livemd` file to see how you can use this library in conjunction with
[VegaLite](https://hexdocs.pm/vega_lite) and [MapLibre](https://hexdocs.pm/maplibre).

## Telemetry

Fred emits [`:telemetry`](https://hexdocs.pm/telemetry) spans for every API request, giving you full
observability over latency, error rates, and usage patterns. For more information, be sure to check out the
`Fred.Telemetry` module.

### Quick Setup - Built-in Logger

The fastest way to see what's happening is to attach the built-in logger handler. Add it to your application's `start/2`
callback:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    # Add this line to attach the logger to the telemetry events
    Fred.Telemetry.Logger.attach()

    children = [
      ...
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
```

With that in place, you should see log output like so whenever you make a call to the Fred API:

```
[info] [fred] GET /series/observations - 200 in 142ms (params: %{series_id: "UNRATE", frequency: :m})
[info] [fred] GET /series - error in 83ms: (400) Bad Request (params: %{series_id: ""})
[info] [fred] GET /series/observations - exception in 5012ms: %Req.TransportError{reason: :timeout}
```

Configure the log level or use a custom handler ID:

```elixir
Fred.Telemetry.Logger.attach(level: :debug, handler_id: "my-fred-log")
```

Detach when you no longer need it:

```elixir
Fred.Telemetry.Logger.detach()
```
