defmodule Fred do
  @moduledoc """
  Elixir client for the FRED (Federal Reserve Economic Data) API.

  The FRED API provides access to hundreds of thousands of economic data series
  from the Federal Reserve Bank of St. Louis.

  ## Setup

  Add your FRED API key to your config:

      # config/config.exs
      config :fred, api_key: "your_api_key_here"

  Or set the `FRED_API_KEY` environment variable.

  You can register for a free API key at:
  https://fred.stlouisfed.org/docs/api/api_key.html

  ## Quick Start

      # Get info about a series
      Fred.Series.get("GDP")

      # Get observations (the actual data values)
      Fred.Series.observations("UNRATE",
        observation_start: "2020-01-01",
        frequency: "q"
      )

      # Search for series
      Fred.Series.search("unemployment rate",
        order_by: "popularity",
        limit: 10
      )

      # Browse categories
      Fred.Categories.get(0)  # root category

  ## API Coverage

  This library covers the complete FRED API v1:

  - `Fred.Categories` — Browse and explore the category tree
  - `Fred.Series` — Fetch series metadata, observations, search, tags, and more
  - `Fred.Releases` — Get information about data releases
  - `Fred.Sources` — Get information about data sources
  - `Fred.Tags` — Browse and search tags assigned to series
  - `Fred.Maps` — GeoFRED geographic/regional data and shape files

  ## Telemetry

  Every API request emits telemetry events via `[:fred, :request]` spans.
  Attach the built-in logger for quick observability:

      # In your Application.start/2:
      Fred.Telemetry.Logger.attach()

  Or attach your own handlers — see `Fred.Telemetry` for event details.

  ## Configuration Options

      config :fred,
        api_key: "your_key",       # Required. Your FRED API key
        base_url: "https://...",   # Optional. Override API base URL
        recv_timeout: 30_000       # Optional. Request timeout in ms (default 30s)
  """

  @doc """
  Returns the configured API key.

  Looks up the key in the following order:
  1. Application config (`:fred, :api_key`)
  2. System environment variable `FRED_API_KEY`

  Raises if no key is found.
  """
  @spec api_key() :: String.t()
  def api_key do
    case Application.get_env(:fred, :api_key) || System.get_env("FRED_API_KEY") do
      nil ->
        raise """
        No FRED API key configured. Set one via:

          config :fred, api_key: "your_key"

        Or set the FRED_API_KEY environment variable.

        Register for a free key at:
        https://fred.stlouisfed.org/docs/api/api_key.html
        """

      key ->
        key
    end
  end

  @doc """
  Returns the configured base URL for the FRED API.
  """
  @spec base_url() :: String.t()
  def base_url do
    Application.get_env(:fred, :base_url, "https://api.stlouisfed.org/fred")
  end
end
