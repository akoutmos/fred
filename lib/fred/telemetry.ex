defmodule Fred.Telemetry do
  @moduledoc """
  Telemetry integration for the Fred library.

  Fred emits telemetry events using `:telemetry.span/3` for every API request.
  Each span produces three possible events:

  ## Events

  ### `[:fred, :request, :start]`

  Emitted when a request begins.

  **Measurements:**

    - `:system_time` — System time at the start of the request (in native units)

  **Metadata:**

    - `:endpoint` — The FRED API path (e.g. `"/series/observations"`)
    - `:base_url` — The base URL used for the request
    - `:params` — The query parameters map (with `:api_key` redacted)

  ### `[:fred, :request, :stop]`

  Emitted when a request completes successfully (the HTTP round-trip finished,
  regardless of API-level errors like 404s).

  **Measurements:**

    - `:duration` — Total wall-clock duration in native time units.
      Convert with `System.convert_time_unit(duration, :native, :millisecond)`.

  **Metadata:**

    - `:endpoint` — The FRED API path
    - `:base_url` — The base URL used
    - `:params` — The query parameters map (with `:api_key` redacted)
    - `:status` — HTTP status code (integer) or `nil` if the request never completed
    - `:result` — `:ok` or `:error`
    - `:error` — The `%Fred.Error{}` struct (only present when `:result` is `:error`)

  ### `[:fred, :request, :exception]`

  Emitted when the request raises an unexpected exception.

  **Measurements:**

    - `:duration` — Wall-clock duration until the exception

  **Metadata:**

    - `:endpoint` — The FRED API path
    - `:base_url` — The base URL used
    - `:params` — The query parameters map (with `:api_key` redacted)
    - `:kind` — The exception kind (`:throw`, `:error`, `:exit`)
    - `:reason` — The exception or thrown value
    - `:stacktrace` — The stacktrace

  ## Attaching Handlers

  You can attach your own handlers to any of these events:

      :telemetry.attach(
        "my-fred-handler",
        [:fred, :request, :stop],
        &MyApp.handle_fred_event/4,
        nil
      )

  Or use the built-in logger for quick observability:

      # In your Application.start/2:
      Fred.Telemetry.Logger.attach()

  ## Event Names

  Use `events/0` to get the list of all event name prefixes for attaching
  to both `:start` and `:stop`:

      Fred.Telemetry.events()
      #=> [[:fred, :request, :start], [:fred, :request, :stop], [:fred, :request, :exception]]
  """

  @doc """
  Executes `fun` inside a `:telemetry.span/3` for `[:fred, :request]`.

  This is used internally by `Fred.Client` and `Fred.Maps` and should not
  normally be called directly.

  ## Parameters

    - `metadata` — A map that must include at least `:endpoint`. Additional
      keys like `:base_url` and `:params` are recommended.
    - `fun` — A zero-arity function that performs the request and returns
      `{:ok, map()}` or `{:error, %Fred.Error{}}`.

  The function's return value is augmented with telemetry metadata and
  passed through transparently.
  """
  @spec span(keyword(), (-> Client.response())) :: Client.response()
  def span(metadata, func) when is_map(metadata) and is_function(func, 0) do
    :telemetry.span([:fred, :request], metadata, fn ->
      case func.() do
        {:ok, _body} = result ->
          extra = %{status: 200, result: :ok}
          {result, Map.merge(metadata, extra)}

        {:error, %Fred.Error{status: status} = error} = result ->
          extra = %{status: status, result: :error, error: error}
          {result, Map.merge(metadata, extra)}
      end
    end)
  end

  @doc """
  Builds the telemetry metadata map for a request making sure to redact
  the API key from params.
  """
  @spec build_metadata(String.t(), keyword()) :: keyword()
  def build_metadata(url, params \\ []) do
    %{
      url: url,
      params: Keyword.replace(params, :api_key, "**REDACTED**")
    }
  end
end
