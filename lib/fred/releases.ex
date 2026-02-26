defmodule Fred.Releases do
  @moduledoc """
  Functions for the FRED Releases endpoints.

  Releases are publications of economic data. For example, the "Employment
  Situation" release includes the unemployment rate, nonfarm payrolls, and
  other labor market series.

  ## Endpoints

    - `list/1` - [`/fred/releases`](https://fred.stlouisfed.org/docs/api/fred/releases.html) - Get all releases
    - `dates/1` - [`/fred/releases/dates`](https://fred.stlouisfed.org/docs/api/fred/releases_dates.html) - Get release dates for all releases
    - `get/2` - [`/fred/release`](https://fred.stlouisfed.org/docs/api/fred/release.html) - Get a specific release
    - `release_dates/2` - [`/fred/release/dates`](https://fred.stlouisfed.org/docs/api/fred/release_dates.html) - Get dates for a specific release
    - `series/2` - [`/fred/release/series`](https://fred.stlouisfed.org/docs/api/fred/release_series.html) - Get series on a release
    - `sources/2` - [`/fred/release/sources`](https://fred.stlouisfed.org/docs/api/fred/release_sources.html) - Get sources for a release
    - `tags/2` - [`/fred/release/tags`](https://fred.stlouisfed.org/docs/api/fred/release_tags.html) - Get tags for a release
    - `related_tags/2` - [`/fred/release/related_tags`](https://fred.stlouisfed.org/docs/api/fred/release_related_tags.html) - Get related tags for a release
    - `tables/2` - [`/fred/release/tables`](https://fred.stlouisfed.org/docs/api/fred/release_tables.html) - Get release tables
  """

  alias Fred.Client
  alias Fred.Utils

  @release_list_schema Utils.generate_schema([
                         :realtime_range,
                         :filter_variable_value,
                         {:pagination, 1_000},
                         {:order_by,
                          [
                            :release_id,
                            :name,
                            :press_release,
                            :realtime_start,
                            :realtime_end
                          ]}
                       ])

  @release_dates_schema Utils.generate_schema([
                          :realtime_range,
                          :filter_variable_value,
                          :include_release_dates_with_no_data,
                          {:pagination, 1_000},
                          {:order_by,
                           [
                             :release_date,
                             :release_id,
                             :release_name
                           ]}
                        ])

  @get_release_schema Utils.generate_schema([
                        :realtime_range
                      ])

  @get_release_dates_schema Utils.generate_schema([
                              :realtime_range,
                              :include_release_dates_with_no_data,
                              :sort_order,
                              {:pagination, 10_000}
                            ])

  @release_series_schema Utils.generate_schema([
                           :realtime_range,
                           :filter_variable_value,
                           :tag_names,
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

  @release_sources_schema Utils.generate_schema([
                            :realtime_range
                          ])

  @release_tags_schema Utils.generate_schema([
                         :realtime_range,
                         :search_text,
                         :tag_group_id,
                         :tag_names,
                         {:pagination, 10_000},
                         {:order_by,
                          [
                            :series_count,
                            :popularity,
                            :created,
                            :name,
                            :group_id
                          ]}
                       ])

  @release_related_tags_schema Utils.generate_schema([
                                 :realtime_range,
                                 :search_text,
                                 :tag_group_id,
                                 :tag_names,
                                 :exclude_tag_names,
                                 {:pagination, 10_000},
                                 {:order_by,
                                  [
                                    :series_count,
                                    :popularity,
                                    :created,
                                    :name,
                                    :group_id
                                  ]}
                               ])

  @doc """
  Get all releases of economic data.

  ## Options

    #{NimbleOptions.docs(@release_list_schema)}

  ## Examples

      iex> {:ok, releases} = Fred.Releases.list(limit: 20, order_by: :name)
      iex> %{"releases" => [_ | _]} = releases

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.list(limit: 20, realtime_start: "Bad Input")
  """
  @spec list(keyword()) :: Client.response()
  def list(opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_list_schema) do
      Client.get_json("/releases", opts)
    end
  end

  @doc """
  Get release dates for all releases of economic data.

  Note that release dates are published by data sources and do not necessarily
  represent when data was available via the FRED API.

  ## Options

    #{NimbleOptions.docs(@release_dates_schema)}

  ## Examples

      iex> {:ok, release_dates} = Fred.Releases.dates(
      ...>   limit: 10,
      ...>   order_by: :release_date,
      ...>   sort_order: :desc
      ...> )
      iex> %{"release_dates" => [_ | _]} = release_dates

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.dates(realtime_start: "Bad Input")
  """
  @spec dates(keyword()) :: Client.response()
  def dates(opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_dates_schema) do
      Client.get_json("/releases/dates", opts)
    end
  end

  @doc """
  Get a release of economic data.

  ## Options

    #{NimbleOptions.docs(@get_release_schema)}

  ## Examples

      iex> {:ok, releases} = Fred.Releases.get(53)
      iex> %{"releases" => [_ | _]} = releases

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.get(53, realtime_start: "Bad Input")
  """
  @spec get(release_id :: integer(), opts :: keyword()) :: Client.response()
  def get(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @get_release_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release", params)
    end
  end

  @doc """
  Get release dates for a specific release of economic data.

  ## Options

    #{NimbleOptions.docs(@get_release_dates_schema)}

  ## Examples

      iex> {:ok, release_dates} = Fred.Releases.release_dates(53, sort_order: :desc, limit: 5)
      iex> %{"release_dates" => [_ | _]} = release_dates

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.release_dates(53, realtime_start: "Bad Input")
  """
  @spec release_dates(release_id :: integer(), opts :: keyword()) :: Client.response()
  def release_dates(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @get_release_dates_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release/dates", params)
    end
  end

  @doc """
  Get the series on a release of economic data.

  ## Options

    #{NimbleOptions.docs(@release_series_schema)}

  ## Examples

      iex> {:ok, release_series} = Fred.Releases.series(50, order_by: :popularity, sort_order: :desc)
      iex> %{"seriess" => [_ | _]} = release_series

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.series(50, order_by: :bad_input, sort_order: :up_down_sideways)
  """
  @spec series(release_id :: integer(), opts :: keyword()) :: Client.response()
  def series(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_series_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release/series", params)
    end
  end

  @doc """
  Get the sources for a release of economic data.

  ## Options

    #{NimbleOptions.docs(@release_sources_schema)}

  ## Examples

      iex> {:ok, release_series} = Fred.Releases.sources(50)
      iex> %{"sources" => [_ | _]} = release_series

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.sources(50, realtime_start: "Bad Input")
  """
  @spec sources(release_id :: integer(), opts :: keyword()) :: Client.response()
  def sources(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_sources_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release/sources", params)
    end
  end

  @doc """
  Get the FRED tags for a release.

  ## Options

    #{NimbleOptions.docs(@release_tags_schema)}

  ## Examples

      iex> {:ok, release_tags} = Fred.Releases.tags(50, tag_group_id: :gen)
      iex> %{"tags" => [_ | _]} = release_tags

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.tags(50, realtime_start: "Bad Input" )
  """
  @spec tags(release_id :: integer(), opts :: keyword()) :: Client.response()
  def tags(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_tags_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release/tags", params)
    end
  end

  @doc """
  Get the related FRED tags for a release.

  ## Options

    #{NimbleOptions.docs(@release_related_tags_schema)}

  ## Examples

      iex> {:ok, release_related_tags} = Fred.Releases.related_tags(50, tag_names: "sa;quarterly")
      iex> %{"tags" => _} = release_related_tags

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.related_tags(50, realtime_start: "Bad Input")
  """
  @spec related_tags(release_id :: integer(), opts :: keyword()) :: Client.response()
  def related_tags(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_related_tags_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release/related_tags", params)
    end
  end

  @release_tables_schema Utils.generate_schema([
                           :element_id,
                           :include_observation_values,
                           {:date, :observation_date, "The observation date."}
                         ])

  @doc """
  Get the release tables for a given release.

  ## Options

    #{NimbleOptions.docs(@release_tables_schema)}

  ## Examples

      iex> {:ok, release_tables} = Fred.Releases.tables(53)
      iex> %{"release_id" => "53", "elements" => _} = release_tables

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Releases.tables(53, realtime_start: "Bad Input")
  """
  @spec tables(release_id :: integer(), opts :: keyword()) :: Client.response()
  def tables(release_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @release_tables_schema) do
      params = Keyword.put(opts, :release_id, release_id)
      Client.get_json("/release/tables", params)
    end
  end
end
