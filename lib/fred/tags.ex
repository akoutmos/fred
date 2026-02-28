defmodule Fred.Tags do
  @moduledoc """
  Functions for the FRED Tags endpoints.

  FRED tags are attributes assigned to series. Tags provide an alternative way
  to find and filter series beyond categories.

  ## Endpoints

    - [`list/1`] - [`fred/tags`](https://fred.stlouisfed.org/docs/api/fred/tags.html) - Get all tags
    - [`related/2`] - [`fred/related_tags`](https://fred.stlouisfed.org/docs/api/fred/related_tags.html) - Get related tags
    - [`series/2`] - [`fred/tags/series`](https://fred.stlouisfed.org/docs/api/fred/tags_series.html) - Get series matching tags
  """

  alias Fred.Client
  alias Fred.Utils

  @tags_list_schema Utils.generate_schema([
                      :realtime_range,
                      :tag_names,
                      :tag_group_id,
                      :search_text,
                      {:pagination, 1_000},
                      {:order_by,
                       [
                         :series_count,
                         :popularity,
                         :created,
                         :name,
                         :group_id
                       ]}
                    ])

  @tags_related_schema Utils.generate_schema([
                         :realtime_range,
                         :search_text,
                         :exclude_tag_names,
                         :tag_group_id,
                         {:pagination, 1_000},
                         {:order_by,
                          [
                            :series_count,
                            :popularity,
                            :created,
                            :name,
                            :group_id
                          ]}
                       ])

  @tags_series_schema Utils.generate_schema([
                        :realtime_range,
                        :exclude_tag_names,
                        {:pagination, 1_000},
                        {:order_by,
                         [
                           :series_id,
                           :title,
                           :units,
                           :frequency,
                           :seasonal_adjustment,
                           :realtime_start,
                           :realtime_end,
                           :last_updated,
                           :observation_start,
                           :observation_end,
                           :popularity,
                           :group_popularity
                         ]}
                      ])
  @doc """
  Get FRED tags, optionally filtered by tag name, group, or search text.

  ## Options

    #{NimbleOptions.docs(@tags_list_schema)}

  ## Examples

      iex> {:ok, tags} = Fred.Tags.list(order_by: :popularity, sort_order: :desc, limit: 10)
      iex> %{"tags" => [_ | _]} = tags

      iex> {:ok, tags} = Fred.Tags.list(order_by: :name, limit: 10)
      iex> %{"tags" => [_ | _]} = tags

      iex> {:ok, tags} = Fred.Tags.list(search_text: "inflation")
      iex> %{"tags" => [_ | _]} = tags

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Tags.list(limit: 20, realtime_start: "Bad Input")
  """
  @spec list(opts :: keyword()) :: Client.response()
  def list(opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @tags_list_schema) do
      Client.get_json("/tags", opts)
    end
  end

  @doc """
  Get the related FRED tags for one or more tags.

  Related tags are tags assigned to series that match all tags in the `:tag_names`
  parameter, excluding the tags themselves.

  ## Options

    #{NimbleOptions.docs(@tags_related_schema)}

  ## Examples

      iex> {:ok, tags} = Fred.Tags.related(["monetary aggregates", "m1"])
      iex> %{"tags" => [_ | _]} = tags

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Tags.related(["monetary aggregates", "m1"], limit: 20, realtime_start: "Bad Input")
  """
  @spec related(tag_names :: String.t(), opts :: keyword()) :: Client.response()
  def related(tag_names, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @tags_related_schema) do
      params = Keyword.put(opts, :tag_names, tag_names)
      Client.get_json("/related_tags", params)
    end
  end

  @doc """
  Get the series matching all tags in the `:tag_names` parameter.

  ## Options

    #{NimbleOptions.docs(@tags_series_schema)}

  ## Examples

      iex> {:ok, series} = Fred.Tags.series(["slovenia", "food", "oecd"], limit: 10)
      iex> %{"seriess" => [_ | _]} = series

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Tags.series(["slovenia", "food", "oecd"], limit: 20, realtime_start: "Bad Input")
  """
  @spec series(tag_names :: nonempty_list(String.t()), opts :: keyword()) :: Client.response()
  def series(tag_names, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @tags_series_schema) do
      params = Keyword.put(opts, :tag_names, tag_names)
      Client.get_json("/tags/series", params)
    end
  end
end
