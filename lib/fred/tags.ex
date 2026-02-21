defmodule Fred.Tags do
  @moduledoc """
  Functions for the FRED Tags endpoints.

  FRED tags are attributes assigned to series. Tags provide an alternative way
  to find and filter series beyond categories. Examples of tags include
  geographic identifiers (`"usa"`, `"state"`), frequencies (`"monthly"`),
  and sources (`"bls"`, `"bea"`).

  ## Tag Groups

    - `"freq"` — Frequency
    - `"gen"` — General or concept
    - `"geo"` — Geography
    - `"geot"` — Geography type
    - `"rls"` — Release
    - `"seas"` — Seasonal adjustment
    - `"src"` — Source
    - `"cc"` — Citation & copyright

  ## Endpoints

    - `list/1` — `fred/tags` — Get all tags
    - `related/1` — `fred/related_tags` — Get related tags
    - `series/1` — `fred/tags/series` — Get series matching tags

  ## Examples

      # Get all tags
      Fred.Tags.list(limit: 20)

      # Search for tags by name
      Fred.Tags.list(search_text: "inflation")

      # Get related tags
      Fred.Tags.related(tag_names: "monetary aggregates;m1")

      # Get series that match specific tags
      Fred.Tags.series(tag_names: "slovenia;food;oecd")
  """

  alias Fred.Client

  @doc """
  Get FRED tags, optionally filtered by tag name, group, or search text.

  ## Parameters

    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:tag_names` — Semicolon-delimited tag names to filter by
      - `:tag_group_id` — Tag group filter. One of: `"freq"`, `"gen"`, `"geo"`,
        `"geot"`, `"rls"`, `"seas"`, `"src"`, `"cc"`
      - `:search_text` — Text to match against tag names
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Examples

      # Get the most popular tags
      Fred.Tags.list(order_by: "popularity", sort_order: "desc", limit: 10)

      # Get geographic tags
      Fred.Tags.list(tag_group_id: "geo", limit: 20)

      # Search for tags
      Fred.Tags.list(search_text: "inflation")
  """
  @spec list(keyword()) :: Client.response()
  def list(opts \\ []) do
    Client.get_json("/tags", opts)
  end

  @doc """
  Get the related FRED tags for one or more tags.

  Related tags are tags assigned to series that match all tags in the `:tag_names`
  parameter, excluding the tags themselves.

  ## Parameters

    - `opts` — Required and optional parameters:
      - `:tag_names` — **Required.** Semicolon-delimited tag names
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude
      - `:tag_group_id` — Tag group filter
      - `:search_text` — Text to match against tag names
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Tags.related(tag_names: "monetary aggregates;m1")
  """
  @spec related(keyword()) :: Client.response()
  def related(opts \\ []) do
    Client.get_json("/related_tags", opts)
  end

  @doc """
  Get the series matching all tags in the `:tag_names` parameter.

  ## Parameters

    - `opts` — Required and optional parameters:
      - `:tag_names` — **Required.** Semicolon-delimited tag names
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_id"`, `"title"`, `"units"`, `"frequency"`,
        `"seasonal_adjustment"`, `"realtime_start"`, `"realtime_end"`,
        `"last_updated"`, `"observation_start"`, `"observation_end"`, `"popularity"`,
        `"group_popularity"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Tags.series(tag_names: "slovenia;food;oecd", limit: 10)
  """
  @spec series(keyword()) :: Client.response()
  def series(opts \\ []) do
    Client.get_json("/tags/series", opts)
  end
end
