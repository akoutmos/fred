defmodule Fred.Series do
  @moduledoc """
  Functions for the FRED Series endpoints.

  Series are the core data type in FRED - each series is a time series of
  economic observations (e.g., GDP, unemployment rate, CPI).

  ## Endpoints

    - `get/2` - `[/fred/series`](https://fred.stlouisfed.org/docs/api/fred/series.html) - Get series metadata
    - `categories/2` - [`/fred/series/categories`](https://fred.stlouisfed.org/docs/api/fred/series_categories.html) - Get categories for a series
    - `observations/2` - [`/fred/series/observations`](https://fred.stlouisfed.org/docs/api/fred/series_observations.html) - Get the actual data values
    - `release/2` - [`/fred/series/release`](https://fred.stlouisfed.org/docs/api/fred/series_release.html) - Get the release a series belongs to
    - `search/2` - [`/fred/series/search`](https://fred.stlouisfed.org/docs/api/fred/series_search.html) - Search for series by text
    - `search_tags/2` - [`/fred/series/search/tags`](https://fred.stlouisfed.org/docs/api/fred/series_search_tags.html) - Get tags for a search
    - `search_related_tags/2` - [`/fred/series/search/related_tags`](https://fred.stlouisfed.org/docs/api/fred/series_search_related_tags.html)
    - `tags/2` - [`/fred/series/tags`](https://fred.stlouisfed.org/docs/api/fred/series_tags.html) - Get tags for a series
    - `updates/1` - [`/fred/series/updates`](https://fred.stlouisfed.org/docs/api/fred/series_updates.html) - Get recently updated series
    - `vintage_dates/2` - [`/fred/series/vintagedates`](https://fred.stlouisfed.org/docs/api/fred/series_vintagedates.html) - Get revision dates
  """

  require Explorer.DataFrame

  alias Explorer.DataFrame
  alias Fred.Client

  @doc """
  Get an economic data series.

  Returns metadata about a series including its title, frequency, units,
  seasonal adjustment, and more.

  ## Parameters

    - `series_id` - The FRED series ID (e.g., `"GDP"`, `"UNRATE"`, `"CPIAUCSL"`)
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)

  ## Example

      {:ok, data} = Fred.Series.get("GDP")
      hd(data["seriess"])["title"]
      #=> "Gross Domestic Product"
  """
  @spec get(String.t(), keyword()) :: Client.response()
  def get(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_json("/series", params)
  end

  @doc """
  Get the categories for an economic data series.

  ## Parameters

    - `series_id` - The FRED series ID
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Series.categories("UNRATE")
  """
  @spec categories(String.t(), keyword()) :: Client.response()
  def categories(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_json("/series/categories", params)
  end

  @doc """
  Get the observations or data values for an economic data series.

  This is the primary function for retrieving actual time series data from FRED.

  ## Parameters

    - `series_id` - The FRED series ID
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)
      - `:limit` - Max results (1–100_000, default: 100_000)
      - `:offset` - Result offset for pagination (default: 0)
      - `:sort_order` - `"asc"` or `"desc"` (default: `"asc"`)
      - `:observation_start` - Start date for observations (YYYY-MM-DD, default: `"1776-07-04"`)
      - `:observation_end` - End date for observations (YYYY-MM-DD, default: `"9999-12-31"`)
      - `:units` - Data value transformation. One of:
        - `"lin"` - Levels (no transformation, default)
        - `"chg"` - Change
        - `"ch1"` - Change from Year Ago
        - `"pch"` - Percent Change
        - `"pc1"` - Percent Change from Year Ago
        - `"pca"` - Compounded Annual Rate of Change
        - `"cch"` - Continuously Compounded Rate of Change
        - `"cca"` - Continuously Compounded Annual Rate of Change
        - `"log"` - Natural Log
      - `:frequency` - Frequency to aggregate to. One of:
        - `"d"` - Daily
        - `"w"` - Weekly
        - `"bw"` - Biweekly
        - `"m"` - Monthly
        - `"q"` - Quarterly
        - `"sa"` - Semiannual
        - `"a"` - Annual
        - `"wef"`, `"weth"`, `"wew"`, `"wetu"`, `"wem"`, `"wesu"`, `"wesa"` - Weekly with specific ending days
        - `"bwew"`, `"bwem"` - Biweekly with specific ending days
      - `:aggregation_method` - Method for frequency aggregation. One of:
        - `"avg"` - Average (default)
        - `"sum"` - Sum
        - `"eop"` - End of Period
      - `:output_type` - Integer 1–4 controlling real-time output format:
        - `1` - Observations by Real-Time Period (default)
        - `2` - Observations by Vintage Date, All Observations
        - `3` - Observations by Vintage Date, New and Revised Observations Only
        - `4` - Observations, Initial Release Only
      - `:vintage_dates` - Comma-separated YYYY-MM-DD dates for historical vintages

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
  @spec observations(String.t(), keyword()) :: Client.response()
  def observations(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_json("/series/observations", params)
  end

  @spec observations(series_ids :: list() | String.t(), opts :: keyword()) :: {:ok, DataFrame.t()} | {:error, term()}
  def observations_as_data_frame(series_ids, opts \\ [])

  def observations_as_data_frame(series_ids, opts) when is_list(series_ids) do
    timeout = Application.get_env(:fred, :timeout, 30_000)

    data_frame =
      series_ids
      |> Task.async_stream(
        fn series_id ->
          case observations(series_id, opts) do
            {:ok, %{"observations" => observations}} when is_list(observations) ->
              {series_id, observations}

            _error ->
              nil
          end
        end,
        max_concurrency: 5,
        timeout: timeout
      )
      |> Enum.reduce([], fn
        {:ok, observations}, acc when not is_nil(observations) ->
          [observations | acc]

        _, acc ->
          acc
      end)
      |> Enum.flat_map(fn {series_id, observations} ->
        observations
        |> Enum.reject(fn
          %{"value" => "."} -> true
          %{"value" => nil} -> true
          _ -> false
        end)
        |> Enum.reduce([], fn observation, acc ->
          case Decimal.parse(observation["value"]) do
            {value, ""} ->
              date = Date.from_iso8601!(observation["date"])
              data = %{date: date, series_id: series_id, value: value}
              [data | acc]

            :error ->
              acc
          end
        end)
      end)
      |> DataFrame.new()

    columns = DataFrame.names(data_frame)

    if "series_id" in columns and "value" in columns do
      data_frame
      |> DataFrame.pivot_wider("series_id", "value")
      |> DataFrame.sort_by(date)
    else
      data_frame
    end
  end

  def observations_as_data_frame(series_id, opts) do
    observations_as_data_frame([series_id], opts)
  end

  @doc """
  Get the release for an economic data series.

  ## Parameters

    - `series_id` - The FRED series ID
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Series.release("GDP")
  """
  @spec release(String.t(), keyword()) :: Client.response()
  def release(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_json("/series/release", params)
  end

  @doc """
  Search for economic data series that match keywords.

  ## Parameters

    - `search_text` - The search query string
    - `opts` - Optional parameters:
      - `:search_type` - One of:
        - `"full_text"` - Searches title, units, frequency, and tags (default)
        - `"series_id"` - Substring search on series IDs
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)
      - `:limit` - Max results (1–1000, default: 1000)
      - `:offset` - Result offset (default: 0)
      - `:order_by` - One of: `"search_rank"`, `"series_id"`, `"title"`, `"units"`,
        `"frequency"`, `"seasonal_adjustment"`, `"realtime_start"`, `"realtime_end"`,
        `"last_updated"`, `"observation_start"`, `"observation_end"`, `"popularity"`,
        `"group_popularity"`
      - `:sort_order` - `"asc"` or `"desc"`
      - `:filter_variable` - One of: `"frequency"`, `"units"`, `"seasonal_adjustment"`
      - `:filter_value` - Value to filter by
      - `:tag_names` - Semicolon-delimited tag names that series must match
      - `:exclude_tag_names` - Semicolon-delimited tag names to exclude

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
  @spec search(String.t(), keyword()) :: Client.response()
  def search(search_text, opts \\ []) do
    params = Keyword.put(opts, :search_text, search_text)
    Client.get_json("/series/search", params)
  end

  @doc """
  Get the tags for a series search.

  Returns the FRED tags that are assigned to series matching the search text.

  ## Parameters

    - `search_text` - The search query string
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)
      - `:tag_names` - Semicolon-delimited tag names to filter by
      - `:tag_group_id` - Tag group filter (`"freq"`, `"gen"`, `"geo"`, `"geot"`,
        `"rls"`, `"seas"`, `"src"`, `"cc"`)
      - `:tag_search_text` - Text to search tag names
      - `:limit` - Max results (1–1000, default: 1000)
      - `:offset` - Result offset (default: 0)
      - `:order_by` - One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` - `"asc"` or `"desc"`

  ## Example

      Fred.Series.search_tags("monetary service index")
  """
  @spec search_tags(String.t(), keyword()) :: Client.response()
  def search_tags(search_text, opts \\ []) do
    params = Keyword.put(opts, :series_search_text, search_text)
    Client.get_json("/series/search/tags", params)
  end

  @doc """
  Get the related tags for a series search.

  Returns tags assigned to series that match all tags in `:tag_names`
  and the search text.

  ## Parameters

    - `search_text` - The search query string
    - `opts` - Required and optional parameters:
      - `:tag_names` - **Required.** Semicolon-delimited tag names
      - `:realtime_start` / `:realtime_end` - Real-time period bounds
      - `:exclude_tag_names` - Semicolon-delimited tag names to exclude
      - `:tag_group_id` - Tag group filter
      - `:tag_search_text` - Text to search within tags
      - `:limit` - Max results (1–1000, default: 1000)
      - `:offset` - Result offset (default: 0)
      - `:order_by` - One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` - `"asc"` or `"desc"`

  ## Example

      Fred.Series.search_related_tags("mortgage rate", tag_names: "30-year;frb")
  """
  @spec search_related_tags(String.t(), keyword()) :: Client.response()
  def search_related_tags(search_text, opts \\ []) do
    params = Keyword.put(opts, :series_search_text, search_text)
    Client.get_json("/series/search/related_tags", params)
  end

  @doc """
  Get the FRED tags for an economic data series.

  ## Parameters

    - `series_id` - The FRED series ID
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)
      - `:order_by` - One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` - `"asc"` or `"desc"`

  ## Example

      Fred.Series.tags("UNRATE")
  """
  @spec tags(String.t(), keyword()) :: Client.response()
  def tags(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_json("/series/tags", params)
  end

  @doc """
  Get economic data series sorted by when observations were updated on the FRED server.

  Results are limited to series updated within the last two weeks.

  ## Parameters

    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)
      - `:limit` - Max results (1–1000, default: 1000)
      - `:offset` - Result offset (default: 0)
      - `:filter_value` - Filter by geographic type. One of:
        `"macro"`, `"regional"`, `"all"` (default: `"all"`)
      - `:start_time` - Start time for filtering updates (YYYY-MM-DD HH:MM:SS)
      - `:end_time` - End time for filtering updates (YYYY-MM-DD HH:MM:SS)

  ## Example

      Fred.Series.updates(limit: 20, filter_value: "macro")
  """
  @spec updates(keyword()) :: Client.response()
  def updates(opts \\ []) do
    Client.get_json("/series/updates", opts)
  end

  @doc """
  Get the dates in history when a series' data values were revised or new data
  values were released.

  Vintage dates are the release dates for a series excluding release dates when
  the data for the series did not change.

  ## Parameters

    - `series_id` - The FRED series ID
    - `opts` - Optional parameters:
      - `:realtime_start` - Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` - End of the real-time period (YYYY-MM-DD)
      - `:limit` - Max results (1–10_000, default: 10_000)
      - `:offset` - Result offset (default: 0)
      - `:sort_order` - `"asc"` or `"desc"` (default: `"asc"`)

  ## Example

      Fred.Series.vintage_dates("GDP")
  """
  @spec vintage_dates(String.t(), keyword()) :: Client.response()
  def vintage_dates(series_id, opts \\ []) do
    params = Keyword.put(opts, :series_id, series_id)
    Client.get_json("/series/vintagedates", params)
  end
end
