defmodule Fred.Categories do
  @moduledoc """
  Functions for the FRED Categories endpoints.

  Categories organize FRED series into a hierarchical tree structure.
  The root category has `category_id` 0.

  ## Endpoints

  Below is a listing of the functions that this module contains along with what endpoints
  they map to in the FRED API. Click on the endpoint to go to the FRED documentation for that
  particular endpoint:

    - `children/2` — [`/fred/category/children`](https://fred.stlouisfed.org/docs/api/fred/category_children.html)
    - `get/2` — [`/fred/category`](https://fred.stlouisfed.org/docs/api/fred/category.html)
    - `related/2` — [`/fred/category/related`](https://fred.stlouisfed.org/docs/api/fred/category_related.html)
    - `related_tags/2` — [`/fred/category/related_tags`](https://fred.stlouisfed.org/docs/api/fred/category_related_tags.html)
    - `series/2` — [`/fred/category/series`](https://fred.stlouisfed.org/docs/api/fred/category_series.html)
    - `tags/2` — [`/fred/category/tags`](https://fred.stlouisfed.org/docs/api/fred/category_tags.html)
  """

  alias Fred.Client
  alias Fred.Utils

  @children_schema NimbleOptions.new!(
                     realtime_start: [
                       doc: "Start of the real-time period",
                       type: {:struct, Date}
                     ],
                     realtime_end: [
                       doc: "End of the real-time period",
                       type: {:struct, Date}
                     ]
                   )

  @doc """
  Get the child categories for a specified parent category.

  ## Options

    #{NimbleOptions.docs(@children_schema)}

  ## Examples

      iex> {:ok, children} = Fred.Categories.children(0)
      iex> %{"categories" => [_ | _]} = children

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Categories.children(0, realtime_start: "Bad Input")
  """
  @spec children(category_id :: integer(), opts :: keyword()) :: Client.response()
  def children(category_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @children_schema) do
      params = Keyword.put(opts, :category_id, category_id)
      Client.get_json("/category/children", params)
    end
  end

  @doc """
  Get a category.

  ## Options

    #{NimbleOptions.docs(@children_schema)}

  ## Examples

      iex> {:ok, category} = Fred.Categories.get(125)
      iex> %{
      ...>   "categories" => [
      ...>     %{"id" => 125, "name" => "Trade Balance", "parent_id" => 13}
      ...>   ]
      ...> } = category

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Categories.get(125, realtime_start: "Bad Input")
  """
  @spec get(category_id :: integer(), opts :: keyword()) :: Client.response()
  def get(category_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @children_schema) do
      params = Keyword.put(opts, :category_id, category_id)
      Client.get_json("/category", params)
    end
  end

  @doc """
  Get the related categories for a given category.

  A related category is a one-way relation between two categories that is not
  part of the parent-child tree structure.

  ## Options

    #{NimbleOptions.docs(@children_schema)}

  ## Examples

      iex> {:ok, categories} = Fred.Categories.related(32073)
      iex> %{"categories" => [_ | _]} = categories

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Categories.related(32073, realtime_start: "Bad Input")
  """
  @spec related(category :: integer(), opts :: keyword()) :: Client.response()
  def related(category_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @children_schema) do
      params = Keyword.put(opts, :category_id, category_id)
      Client.get_json("/category/related", params)
    end
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

  ## Examples

      iex> {:ok, series} = Fred.Categories.series(125, limit: 10, order_by: "popularity", sort_order: "desc")
      iex> %{"seriess" => [_ | _]} = series
  """
  @spec series(category :: integer(), opts :: keyword()) :: Client.response()
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

  ## Examples

      iex> {:ok, tags} = Fred.Categories.tags(125, tag_group_id: "freq")
      iex> %{"tags" => [_ | _]} = tags
  """
  @spec tags(category :: integer(), opts :: keyword()) :: Client.response()
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

  ## Examples

      iex> {:ok, tags} = Fred.Categories.related_tags(125, tag_names: "services;quarterly")
      iex> %{"tags" => [_ | _]} = tags
  """
  @spec related_tags(category :: integer(), opts :: keyword()) :: Client.response()
  def related_tags(category_id, opts \\ []) do
    params = Keyword.put(opts, :category_id, category_id)
    Client.get_json("/category/related_tags", params)
  end
end
