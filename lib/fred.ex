defmodule Fred do
  @moduledoc """
  Elixir client for the [FRED (Federal Reserve Economic Data) API](https://fred.stlouisfed.org/docs/api/fred/).

  The FRED API provides access to thousands of economic data series
  from the Federal Reserve Bank of St. Louis.

  ## Setup

  In order to use the FRED API client library, you'll need to have
  an account with FRED so that you can use the API. You can create
  an account for free from the [FRED website](https://fred.stlouisfed.org/docs/api/api_key.html)

  After you have created an account, you can configure this library
  via your config file like so:

  ```elixir
  # config/runtime.exs
  import Config

  config :fred,
    api_key: System.fetch_env!("FRED_API_KEY")
  ```

  With your API key configured, you can now make calls to the FRED API
  to fetch economic data.

  ## Run Your First Query

  With your API key configured, you can make calls to the FRED API like so:

  ```elixir
  iex(1)> Fred.Series.get("GDP")
  {:ok,
   %{
     "realtime_end" => "2026-02-20",
     "realtime_start" => "2026-02-20",
     "seriess" => [
       %{
         "frequency" => "Quarterly",
         "frequency_short" => "Q",
         "id" => "GDP",
         ...
       }
     ]
   }}
  ```

  ## API Coverage

  This library provides coverage for the whole
  [FRED v1 API](https://fred.stlouisfed.org/docs/api/fred/) including Maps:

  - `Fred.Categories` — Browse and explore the category tree
  - `Fred.Series` — Fetch series metadata, observations, search, and tags
  - `Fred.Releases` — Get information about data releases
  - `Fred.Sources` — Get information about data sources
  - `Fred.Tags` — Browse and search tags assigned to series
  - `Fred.Maps` — GeoFRED geographic/regional data and shape files

  ## Telemetry

  So that you have the ability to hook into requests being made to FRED,
  this library emits telemetry events whenever an API call is made. The
  following telemetry events are emitted:

  - [:fred, :request, :init, :start] - When an API request is initiated
  - [:fred, :request, :init, :stop] - When an API call completes
  - [:fred, :request, :init, :exception] - When an exception occurs during the API call

  For more details on the measurements and metadata provided in each
  event, be sure to take a look at the `Fred.Telemetry` module docs.

  ### Default Logger

  For your convenience, this library provides a default Logger that
  leverages the aforementioned telemetry events. You can set up the
  default Logger by running the following in your `Application.start/2`
  callback:

  ```elixir
  Fred.Telemetry.Logger.attach()
  ```

  ## Configuration Options

  Aside from your FRED API key, you can also configure the timeout
  for each request to the API:

  ```elixir
  config :fred,
    api_key: System.fetch_env!("FRED_API_KEY"), # Required. Your FRED API key
    timeout: 30_000                             # Optional. Request timeout in ms (default 30s)
  ```
  """
end
