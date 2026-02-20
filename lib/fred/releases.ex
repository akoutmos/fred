defmodule Fred.Releases do
  @moduledoc """
  Functions for the FRED Releases endpoints.

  Releases are publications of economic data. For example, the "Employment
  Situation" release includes the unemployment rate, nonfarm payrolls, and
  other labor market series.

  ## Endpoints

    - `list/1` — `fred/releases` — Get all releases
    - `dates/1` — `fred/releases/dates` — Get release dates for all releases
    - `get/2` — `fred/release` — Get a specific release
    - `release_dates/2` — `fred/release/dates` — Get dates for a specific release
    - `series/2` — `fred/release/series` — Get series on a release
    - `sources/2` — `fred/release/sources` — Get sources for a release
    - `tags/2` — `fred/release/tags` — Get tags for a release
    - `related_tags/2` — `fred/release/related_tags` — Get related tags for a release
    - `tables/2` — `fred/release/tables` — Get release tables

  ## Examples

      # List all releases
      Fred.Releases.list()

      # Get upcoming release dates
      Fred.Releases.dates(include_release_dates_with_no_data: "true")

      # Get series on the Employment Situation release
      Fred.Releases.series(50)
  """

  @doc """
  Get all releases of economic data.

  ## Parameters

    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"release_id"`, `"name"`, `"press_release"`,
        `"realtime_start"`, `"realtime_end"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Releases.list(limit: 20, order_by: "name")
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def list(opts \\ []) do
    Fred.Client.get("/releases", opts)
  end

  @doc """
  Get release dates for all releases of economic data.

  Note that release dates are published by data sources and do not necessarily
  represent when data was available via the FRED API.

  ## Parameters

    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"release_date"`, `"release_id"`, `"release_name"`
      - `:sort_order` — `"asc"` or `"desc"`
      - `:include_release_dates_with_no_data` — `"true"` to include future
        release dates with no data yet (default: `"false"`)

  ## Example

      Fred.Releases.dates(
        limit: 10,
        order_by: "release_date",
        sort_order: "desc"
      )
  """
  @spec dates(keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def dates(opts \\ []) do
    Fred.Client.get("/releases/dates", opts)
  end

  @doc """
  Get a release of economic data.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Releases.get(53)  # GDP release
  """
  @spec get(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def get(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release", &1))
  end

  @doc """
  Get release dates for a specific release of economic data.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–10_000, default: 10_000)
      - `:offset` — Result offset (default: 0)
      - `:sort_order` — `"asc"` or `"desc"`
      - `:include_release_dates_with_no_data` — `"true"` or `"false"` (default)

  ## Example

      Fred.Releases.release_dates(53, sort_order: "desc", limit: 5)
  """
  @spec release_dates(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def release_dates(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release/dates", &1))
  end

  @doc """
  Get the series on a release of economic data.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_id"`, `"title"`, `"units"`, `"frequency"`,
        `"seasonal_adjustment"`, `"realtime_start"`, `"realtime_end"`,
        `"last_updated"`, `"observation_start"`, `"observation_end"`, `"popularity"`,
        `"group_popularity"`
      - `:sort_order` — `"asc"` or `"desc"`
      - `:filter_variable` — One of: `"frequency"`, `"units"`, `"seasonal_adjustment"`
      - `:filter_value` — Value to filter by
      - `:tag_names` — Semicolon-delimited tag names to match
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude

  ## Example

      Fred.Releases.series(50, order_by: "popularity", sort_order: "desc")
  """
  @spec series(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def series(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release/series", &1))
  end

  @doc """
  Get the sources for a release of economic data.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Releases.sources(50)
  """
  @spec sources(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def sources(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release/sources", &1))
  end

  @doc """
  Get the FRED tags for a release.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:tag_names` — Semicolon-delimited tag names to filter by
      - `:tag_group_id` — Tag group filter
      - `:search_text` — Text to search tag names
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Releases.tags(50, tag_group_id: "gen")
  """
  @spec tags(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def tags(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release/tags", &1))
  end

  @doc """
  Get the related FRED tags for a release.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Required and optional parameters:
      - `:tag_names` — **Required.** Semicolon-delimited tag names
      - `:realtime_start` / `:realtime_end` — Real-time period bounds
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude
      - `:tag_group_id` — Tag group filter
      - `:search_text` — Text to search within tags
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Releases.related_tags(50, tag_names: "sa;quarterly")
  """
  @spec related_tags(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def related_tags(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release/related_tags", &1))
  end

  @doc """
  Get the release tables for a given release.

  ## Parameters

    - `release_id` — The ID of the release
    - `opts` — Optional parameters:
      - `:element_id` — The release table element ID to retrieve
      - `:include_observation_values` — `"true"` or `"false"` (default)
      - `:observation_date` — The observation date (YYYY-MM-DD, default: latest)

  ## Example

      Fred.Releases.tables(53)
  """
  @spec tables(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def tables(release_id, opts \\ []) do
    opts
    |> Keyword.put(:release_id, release_id)
    |> then(&Fred.Client.get("/release/tables", &1))
  end
end
