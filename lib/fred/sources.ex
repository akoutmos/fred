defmodule Fred.Sources do
  @moduledoc """
  Functions for the FRED Sources endpoints.

  Sources are the original providers of economic data to FRED (e.g., the Bureau
  of Labor Statistics, the Bureau of Economic Analysis, the Federal Reserve Board).

  ## Endpoints

    - `list/1` — `fred/sources` — Get all sources
    - `get/2` — `fred/source` — Get a specific source
    - `releases/2` — `fred/source/releases` — Get releases for a source

  ## Examples

      # List all sources
      Fred.Sources.list()

      # Get BLS source info
      Fred.Sources.get(6)

      # Get releases from a source
      Fred.Sources.releases(1, order_by: "name")
  """

  @doc """
  Get all sources of economic data.

  ## Parameters

    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"source_id"`, `"name"`, `"realtime_start"`, `"realtime_end"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Sources.list(limit: 10, order_by: "name")
  """
  @spec list(keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def list(opts \\ []) do
    Fred.Client.get("/sources", opts)
  end

  @doc """
  Get a source of economic data.

  ## Parameters

    - `source_id` — The ID of the source
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)

  ## Example

      Fred.Sources.get(1)  # Board of Governors
  """
  @spec get(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def get(source_id, opts \\ []) do
    opts
    |> Keyword.put(:source_id, source_id)
    |> then(&Fred.Client.get("/source", &1))
  end

  @doc """
  Get the releases for a source.

  ## Parameters

    - `source_id` — The ID of the source
    - `opts` — Optional parameters:
      - `:realtime_start` — Start of the real-time period (YYYY-MM-DD)
      - `:realtime_end` — End of the real-time period (YYYY-MM-DD)
      - `:limit` — Max results (1–1000, default: 1000)
      - `:offset` — Result offset (default: 0)
      - `:order_by` — One of: `"release_id"`, `"name"`, `"press_release"`,
        `"realtime_start"`, `"realtime_end"`
      - `:sort_order` — `"asc"` or `"desc"`

  ## Example

      Fred.Sources.releases(1, order_by: "name")
  """
  @spec releases(integer(), keyword()) :: {:ok, map()} | {:error, Fred.Error.t()}
  def releases(source_id, opts \\ []) do
    opts
    |> Keyword.put(:source_id, source_id)
    |> then(&Fred.Client.get("/source/releases", &1))
  end
end
