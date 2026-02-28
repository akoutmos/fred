defmodule Fred.Telemetry do
  @moduledoc """
  Telemetry integration for the Fred library.

  Fred emits telemetry events using `:telemetry.span/3` for every API request.
  Each span produces three possible events:

  ## Events

  ### `[:fred, :request, :start]`

  Emitted when a request begins.

  **Measurements:**

    - `:system_time` - System time at the start of the request (in native units)

  **Metadata:**

    - `:url` - The requested URL
    - `:params` - The query parameters map (with `:api_key` redacted)

  ### `[:fred, :request, :stop]`

  Emitted when a request completes successfully (the HTTP round-trip finished,
  regardless of API-level errors like 404s).

  **Measurements:**

    - `:duration` - Total wall-clock duration in native time units.
      Convert with `System.convert_time_unit(duration, :native, :millisecond)`.

  **Metadata:**

    - `:url` - The requested URL
    - `:params` - The query parameters map (with `:api_key` redacted)
    - `:status` - HTTP status code (integer) or `nil` if the request never completed
    - `:result` - `:ok` or `:error`
    - `:error` - The `%Fred.Error{}` struct (only present when `:result` is `:error`)

  ### `[:fred, :request, :exception]`

  Emitted when the request raises an unexpected exception.

  **Measurements:**

    - `:duration` - Wall-clock duration until the exception

  **Metadata:**

    - `:url` - The requested URL
    - `:params` - The query parameters map (with `:api_key` redacted)
    - `:kind` - The exception kind (`:throw`, `:error`, `:exit`)
    - `:reason` - The exception or thrown value
    - `:stacktrace` - The stacktrace

  ## Attaching Handlers

  You can attach your own handlers to any of these events:

  ```elixir
  :telemetry.attach(
    "my-fred-handler",
    [:fred, :request, :stop],
    &MyApp.handle_fred_event/4,
    nil
  )
  ```

  Or use the built-in logger for quick request observability:

  ```elixir
  # In your Application.start/2:
  Fred.Telemetry.Logger.attach()
  ```
  """

  alias Fred.Client

  @doc false
  @spec span(metadata :: map(), func :: (-> Client.response())) :: Client.response()
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

  @doc false
  @spec build_metadata(url :: String.t(), params :: keyword()) :: %{:params => Keyword.t(), :url => String.t()}
  def build_metadata(url, params \\ []) do
    %{
      url: url,
      params: Keyword.delete(params, :api_key)
    }
  end
end
