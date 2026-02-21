defmodule Fred.Categories do
  @moduledoc """
  Functions for the FRED Categories endpoints.

  Categories organize FRED series into a hierarchical tree structure.
  The root category has `category_id` 0.

  ## Endpoints

    - `get/2` — `fred/category`
    - `children/2` — `fred/category/children`
    - `related/2` — `fred/category/related`
    - `series/2` — `fred/category/series`
    - `tags/2` — `fred/category/tags`
    - `related_tags/2` — `fred/category/related_tags`

  ## Examples

      # Get the root category
      Fred.Categories.get(0)

      # Get child categories of "Production & Business Activity" (category_id: 1)
      Fred.Categories.children(1)

      # Get series in a category with filters
      Fred.Categories.series(125,
        order_by: "popularity",
        sort_order: "desc",
        limit: 10
      )
  """

  alias Fred.Client

  @doc """
  Get a category.

  ## Parameters

    - `category_id` — The ID of the category (use `0` for root)
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Categories.get(125)
  """
  @spec get(category_id :: integer(), opts :: keyword()) :: Client.response()
  def get(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category", params)
  end

  @doc """
  Get the child categories for a specified parent category.

  ## Parameters

    - `category_id` — The ID of the parent category
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Categories.children(0)
  """
  @spec children(integer(), keyword()) :: Client.response()
  def children(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category/children", params)
  end

  @doc """
  Get the related categories for a category.

  A related category is a one-way relation between two categories that is not
  part of the parent-child tree structure.

  ## Parameters

    - `category_id` — The ID of the category
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Categories.related(32073)
  """
  @spec related(integer(), keyword()) :: Client.response()
  def related(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category/related", params)
  end

  @doc """
  Get the series in a category.

  ## Parameters

    - `category_id` — The ID of the category
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
      - `:filter_value` — Value to filter by (requires `:filter_variable`)
      - `:tag_names` — Semicolon-delimited tag names to match
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude

  ## Example

      Fred.Categories.series(125, limit: 10, order_by: "popularity", sort_order: "desc")
  """
  @spec series(integer(), keyword()) :: Client.response()
  def series(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category/series", params)
  end

  @doc """
  Get the FRED tags for a category.

  ## Parameters

    - `category_id` — The ID of the category
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:tag_names` — Semicolon-delimited tag names to filter by
      - `:tag_group_id` — Tag group filter. One of: `"freq"`, `"gen"`, `"geo"`,
        `"geot"`, `"rls"`, `"seas"`, `"src"`, `"cc"`
      - `:search_text` — Text to search tag names and values
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Categories.tags(125, tag_group_id: "freq")
  """
  @spec tags(integer(), keyword()) :: Client.response()
  def tags(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category/tags", params)
  end

  @doc """
  Get the related FRED tags for a category.

  Related tags are tags assigned to series that match all tags in `:tag_names`.

  ## Parameters

    - `category_id` — The ID of the category
    - `opts` — Required and optional parameters:
      - `:tag_names` — **Required.** Semicolon-delimited tag names
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:exclude_tag_names` — Semicolon-delimited tag names to exclude
      - `:tag_group_id` — Tag group filter
      - `:search_text` — Text to search tag names and values
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"series_count"`, `"popularity"`, `"created"`,
        `"name"`, `"group_id"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Categories.related_tags(125, tag_names: "services;quarterly")
  """
  @spec related_tags(integer(), keyword()) :: Client.response()
  def related_tags(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category/related_tags", params)
  end
end
