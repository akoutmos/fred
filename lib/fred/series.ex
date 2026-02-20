defmodule Fred.Series do
  @moduledoc """
  Functions for the FRED Series endpoints.

  Series are the core data type in FRED — each series is a time series of
  economic observations (e.g., GDP, unemployment rate, CPI).

  ## Endpoints

    - `get/2` — `fred/series` — Get series metadata
    - `categories/2` — `fred/series/categories` — Get categories for a series
    - `observations/2` — `fred/series/observations` — Get the actual data values
    - `release/2` — `fred/series/release` — Get the release a series belongs to
    - `search/2` — `fred/series/search` — Search for series by text
    - `search_tags/2` — `fred/series/search/tags` — Get tags for a search
    - `search_related_tags/2` — `fred/series/search/related_tags`
    - `tags/2` — `fred/series/tags` — Get tags for a series
    - `updates/1` — `fred/series/updates` — Get recently updated series
    - `vintage_dates/2` — `fred/series/vintagedates` — Get revision dates

  ## Examples

      # Get series metadata
      Fred.Series.get("GDP")

      # Fetch monthly unemployment observations since 2020
      Fred.Series.observations("UNRATE",
        observation_start: "2020-01-01",
        frequency: "m"
      )

      # Search for series about inflation
      Fred.Series.search("consumer price index",
        order_by: "popularity",
        sort_order: "desc",
        limit: 5
      )
  """

  @doc """
  Get an economic data series.

  Returns metadata about a series including its title, frequency, units,
  seasonal adjustment, and more.

  ## Parameters

    - `series_id` — The FRED series ID (e.g., `"GDP"`, `"UNRATE"`, `"CPIAUCSL"`)
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      {:ok, data} = Fred.Series.get("GDP")
      hd(data["seriess"])["title"]
      #=> "Gross Domestic Product"
  """
  @spec get(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def get(series_id, opts \\ []) do
    opts
    |> Keyword.put(:series_id, series_id)
    |> then(&Fred.Client.get("/series", &1))
  end

  @doc """
  Get the categories for an economic data series.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Series.categories("UNRATE")
  """
  @spec categories(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def categories(series_id, opts \\ []) do
    opts
    |> Keyword.put(:series_id, series_id)
    |> then(&Fred.Client.get("/series/categories", &1))
  end

  @doc """
  Get the observations or data values for an economic data series.

  This is the primary function for retrieving actual time series data from FRED.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–100_000, default: 100_000)
      - `:offset` — Result offset for pagination (default: 0)
      - `:sort_order` — `"asc"` or `"desc"` (default: `"asc"`)
      - `:observation_start` — Start date for observations (YYYY-MM-DD, default: `"1776-07-04"`)
      - `:observation_end` — End date for observations (YYYY-MM-DD, default: `"9999-12-31"`)
      - `:units` — Data value transformation. One of:
        - `"lin"` — Levels (no transformation, default)
        - `"chg"` — Change
        - `"ch1"` — Change from Year Ago
        - `"pch"` — Percent Change
        - `"pc1"` — Percent Change from Year Ago
        - `"pca"` — Compounded Annual Rate of Change
        - `"cch"` — Continuously Compounded Rate of Change
        - `"cca"` — Continuously Compounded Annual Rate of Change
        - `"log"` — Natural Log
      - `:frequency` — Frequency to aggregate to. One of:
        - `"d"` — Daily
        - `"w"` — Weekly
        - `"bw"` — Biweekly
        - `"m"` — Monthly
        - `"q"` — Quarterly
        - `"sa"` — Semiannual
        - `"a"` — Annual
        - `"wef"`, `"weth"`, `"wew"`, `"wetu"`, `"wem"`, `"wesu"`, `"wesa"` — Weekly with specific ending days
        - `"bwew"`, `"bwem"` — Biweekly with specific ending days
      - `:aggregation_method` — Method for frequency aggregation. One of:
        - `"avg"` — Average (default)
        - `"sum"` — Sum
        - `"eop"` — End of Period
      - `:output_type` — Integer 1–4 controlling real-time output format:
        - `1` — Observations by Real-Time Period (default)
        - `2` — Observations by Vintage Date, All Observations
        - `3` — Observations by Vintage Date, New and Revised Observations Only
        - `4` — Observations, Initial Release Only
      - `:vintage_dates` — Comma-separated YYYY-MM-DD dates for historical vintages

  ## Examples

      # Basic observations
      Fred.Series.observations("UNRATE")

      # Quarterly GDP percent change since 2020
      Fred.Series.observations("GDP",
        observation_start: "2020-01-01",
        frequency: "q",
        units: "pch"
      )

      # Get data as it was known on a specific date
      Fred.Series.observations("GDP",
        vintage_dates: "2015-01-01,2015-07-01"
      )
  """
  @spec observations(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def observations(series_id, opts \\ []) do
    opts
    |> Keyword.put(:series_id, series_id)
    |> then(&Fred.Client.get("/series/observations", &1))
  end

  @doc """
  Get the release for an economic data series.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Series.release("GDP")
  """
  @spec release(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def release(series_id, opts \\ []) do
    opts
    |> Keyword.put(:series_id, series_id)
    |> then(&Fred.Client.get("/series/release", &1))
  end

  @doc """
  Search for economic data series that match keywords.

  ## Parameters

    - `search_text` — The search query string
    - `opts` — Optional parameters:
      - `:search_type` — One of:
        - `"full_text"` — Searches title, units, frequency, and tags (default)
        - `"series_id"` — Substring search on series IDs
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"search_rank"`, `"series_id"`, `"title"`, `"units"`,
        `"frequency"`, `"seasonal_adjustment"`, `"realtime_start"`, `"realtime_end"`,
        `"last_updated"`, `"observation_start"`, `"observation_end"`, `"popularity"`,
        `"group_popularity"`
      - `:sort_order` — `"asc"` or `"desc"`
      - `:filter_variable` — One of: `"frequency"`, `"units"`, `"seasonal_adjustment"`
      - `:filter_value` — Value to filter by
      - `:tag_names` — Semicolon-delimited tag names that series must match
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude

  ## Examples

      # Search by text
      Fred.Series.search("unemployment rate",
        order_by: "popularity",
        sort_order: "desc",
        limit: 10
      )

      # Search by series ID
      Fred.Series.search("UNRATE", search_type: "series_id")

      # Filter to monthly series about GDP
      Fred.Series.search("gdp",
        filter_variable: "frequency",
        filter_value: "Monthly"
      )
  """
  @spec search(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def search(search_text, opts \\ []) do
    opts
    |> Keyword.put(:search_text, search_text)
    |> then(&Fred.Client.get("/series/search", &1))
  end

  @doc """
  Get the tags for a series search.

  Returns the FRED tags that are assigned to series matching the search text.

  ## Parameters

    - `search_text` — The search query string
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:tag_names` — Semicolon-delimited tag names to filter by
      - `:tag_group_id` — Tag group filter (`"freq"`, `"gen"`, `"geo"`, `"geot"`,
        `"rls"`, `"seas"`, `"src"`, `"cc"`)
      - `:tag_search_text` — Text to search tag names
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Series.search_tags("monetary service index")
  """
  @spec search_tags(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def search_tags(search_text, opts \\ []) do
    opts
    |> Keyword.put(:series_search_text, search_text)
    |> then(&Fred.Client.get("/series/search/tags", &1))
  end

  @doc """
  Get the related tags for a series search.

  Returns tags assigned to series that match all tags in `:tag_names`
  and the search text.

  ## Parameters

    - `search_text` — The search query string
    - `opts` — Required and optional parameters:
      - `:tag_names` — **Required.** Semicolon-delimited tag names
      - `:realtime_start` / `:realtime_end` — Real-time period bounds
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude
      - `:tag_group_id` — Tag group filter
      - `:tag_search_text` — Text to search within tags
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Series.search_related_tags("mortgage rate", tag_names: "30-year;frb")
  """
  @spec search_related_tags(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def search_related_tags(search_text, opts \\ []) do
    opts
    |> Keyword.put(:series_search_text, search_text)
    |> then(&Fred.Client.get("/series/search/related_tags", &1))
  end

  @doc """
  Get the FRED tags for an economic data series.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Series.tags("UNRATE")
  """
  @spec tags(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def tags(series_id, opts \\ []) do
    opts
    |> Keyword.put(:series_id, series_id)
    |> then(&Fred.Client.get("/series/tags", &1))
  end

  @doc """
  Get economic data series sorted by when observations were updated on the FRED server.

  Results are limited to series updated within the last two weeks.

  ## Parameters

    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:filter_value` — Filter by geographic type. One of:
        `"macro"`, `"regional"`, `"all"` (default: `"all"`)
      - `:start_time` — Start time for filtering updates (YYYY-MM-DD HH:MM:SS)
      - `:end_time` — End time for filtering updates (YYYY-MM-DD HH:MM:SS)

  ## Example

      Fred.Series.updates(limit: 20, filter_value: "macro")
  """
  @spec updates(keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def updates(opts \\ []) do
    Fred.Client.get("/series/updates", opts)
  end

  @doc """
  Get the dates in history when a series' data values were revised or new data
  values were released.

  Vintage dates are the release dates for a series excluding release dates when
  the data for the series did not change.

  ## Parameters

    - `series_id` — The FRED series ID
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–10_000, default: 10_000)
      - `:offset` — Result offset (default: 0)
      - `:sort_order` — `"asc"` or `"desc"` (default: `"asc"`)

  ## Example

      Fred.Series.vintage_dates("GDP")
  """
  @spec vintage_dates(String.t(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def vintage_dates(series_id, opts \\ []) do
    opts
    |> Keyword.put(:series_id, series_id)
    |> then(&Fred.Client.get("/series/vintagedates", &1))
  end
end
