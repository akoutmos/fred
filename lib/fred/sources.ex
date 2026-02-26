defmodule Fred.Sources do
  @moduledoc """
  Functions for the FRED Sources endpoints.

  Sources are the original providers of economic data to FRED (e.g., the Bureau
  of Labor Statistics, the Bureau of Economic Analysis, the Federal Reserve Board).

  ## Endpoints

    - `list/1` - [`/fred/sources`](https://fred.stlouisfed.org/docs/api/fred/sources.html)
    - `get/2` - [`/fred/source`](https://fred.stlouisfed.org/docs/api/fred/source.html)
    - `releases/2` - [`/fred/source/releases`](https://fred.stlouisfed.org/docs/api/fred/source_releases.html)
  """

  alias Fred.Client
  alias Fred.Utils

  @source_list_schema Utils.generate_schema([
                        :realtime_range,
                        {:pagination, 1_000},
                        {:order_by,
                         [
                           :source_id,
                           :name,
                           :press_release,
                           :realtime_start,
                           :realtime_end
                         ]}
                      ])

  @source_get_schema Utils.generate_schema([
                       :realtime_range
                     ])

  @source_releases_schema Utils.generate_schema([
                            :realtime_range,
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

  @doc """
  Get all sources of economic data.

  ## Options

    #{NimbleOptions.docs(@source_list_schema)}

  ## Examples

      iex> {:ok, sources} = Fred.Sources.list(limit: 10, order_by: :name)
      iex> %{"sources" => [_ | _]} = sources

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Sources.list(limit: 10, realtime_start: "Bad Input")
  """
  @spec list(opts :: keyword()) :: Client.response()
  def list(opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @source_list_schema) do
      Client.get_json("/sources", opts)
    end
  end

  @doc """
  Get a source of economic data.

  ## Options

    #{NimbleOptions.docs(@source_get_schema)}

  ## Examples

      iex> {:ok, sources} = Fred.Sources.get(1)
      iex> %{"sources" => [_ | _]} = sources

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Sources.get(1, realtime_start: "Bad Input")
  """
  @spec get(source_id :: integer(), opts :: keyword()) :: Client.response()
  def get(source_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @source_get_schema) do
      params = Keyword.put(opts, :source_id, source_id)
      Client.get_json("/source", params)
    end
  end

  @doc """
  Get the releases for a source.

  ## Options

    #{NimbleOptions.docs(@source_releases_schema)}

  ## Examples

      iex> {:ok, releases} = Fred.Sources.releases(1, order_by: :name)
      iex> %{"releases" => [_ | _]} = releases

      iex> {:error, %Fred.Error{type: :option_error}} =
      ...>   Fred.Sources.releases(1, realtime_start: "Bad Input")
  """
  @spec releases(source_id :: integer(), opts :: keyword()) :: Client.response()
  def releases(source_id, opts \\ []) do
    with :ok <- Utils.validate_opts(opts, @source_releases_schema) do
      params = Keyword.put(opts, :source_id, source_id)
      Client.get_json("/source/releases", params)
    end
  end
end
