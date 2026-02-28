defmodule Fred.Telemetry.Logger do
  @moduledoc """
  A built-in telemetry handler that logs FRED API request details using Elixir's `Logger`.

  Attach it in your application's `start/2` callback for quick observability:

  ```elixir
  def start(_type, _args) do
    Fred.Telemetry.Logger.attach()

    # ...
  end
  ```

  ## Output

  On every completed request (`:stop` event) it logs at the configured level:

  ```
  [fred] GET /series/observations - 200 in 142ms (params: %{series_id: "UNRATE", frequency: :m})
  ```

  On errors:

  ```
  [fred] GET /series/observations - error in 83ms: (400) Bad Request (params: %{series_id: ""})
  ```

  On exceptions (`:exception` event):

  ```
  [fred] GET /series/observations - exception in 5012ms: %Req.TransportError{reason: :timeout}
  ```

  ## Configuration

  Pass options to `attach/1` to customize behavior:

  ```
  Fred.Telemetry.Logger.attach(
    level: :info,              # Logger level (default: :info)
    handler_id: "my-fred-log"  # Unique handler ID (default: "fred-default-logger")
  )
  ```

  ## Detaching

  To stop logging, detach by handler ID:

  ```
  Fred.Telemetry.Logger.detach()

  # or with a custom ID:

  Fred.Telemetry.Logger.detach("my-fred-log")
  ```
  """

  require Logger

  @default_id "fred-default-logger"

  @doc """
  Attaches the logger handler to FRED telemetry events.

  ## Options

    - `:level` - The `Logger` level to log at. Default: `:info`
    - `:handler_id` - A unique string ID for this handler. Default: `"fred-default-logger"`.
      Useful if you want to attach multiple loggers with different configs.

  Returns `:ok` or `{:error, :already_exists}` if the handler ID is taken.
  """
  @spec attach(keyword()) :: :ok | {:error, :already_exists}
  def attach(opts \\ []) do
    level = Keyword.get(opts, :level, :info)
    handler_id = Keyword.get(opts, :handler_id, @default_id)

    events = [
      [:fred, :request, :stop],
      [:fred, :request, :exception]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      &__MODULE__.handle_event/4,
      %{level: level}
    )
  end

  @doc """
  Detaches the logger handler.

  ## Parameters

    - `handler_id` - The handler ID to detach. Default: `"fred-default-logger"`
  """
  @spec detach(String.t()) :: :ok | {:error, :not_found}
  def detach(handler_id \\ @default_id) do
    :telemetry.detach(handler_id)
  end

  @doc false
  def handle_event([:fred, :request, :stop], measurements, metadata, config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    endpoint = metadata.url |> URI.parse() |> Map.fetch!(:path)
    params = metadata[:params] || %{}
    status = metadata[:status]
    result = metadata[:result]

    message =
      case result do
        :ok ->
          "[fred] GET #{endpoint} - #{status} in #{duration_ms}ms#{format_params(params)}"

        :error ->
          error = metadata[:error]
          error_detail = if error, do: ": #{Exception.message(error)}", else: ""

          "[fred] GET #{endpoint} - error in #{duration_ms}ms#{error_detail}#{format_params(params)}"
      end

    Logger.log(config.level, message)
  end

  def handle_event([:fred, :request, :exception], measurements, metadata, config) do
    duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
    endpoint = metadata.url |> URI.parse() |> Map.fetch!(:path)
    params = metadata[:params] || %{}
    reason = metadata[:reason]

    message =
      "[fred] GET #{endpoint} - exception in #{duration_ms}ms: #{inspect(reason)}#{format_params(params)}"

    Logger.log(config.level, message)
  end

  defp format_params(params) when map_size(params) == 0, do: ""

  defp format_params(params) do
    display =
      params
      |> Keyword.drop([:file_type])
      |> inspect(pretty: false)

    " (params: #{display})"
  end
end
