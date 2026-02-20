defmodule Fred.Client do
  @moduledoc """
  Low-level HTTP client for the FRED API using Req.

  Handles request construction, parameter serialization, response parsing,
  and telemetry instrumentation.

  All endpoint modules delegate to this module for actual HTTP communication.

  ## Telemetry

  Every request is wrapped in a `[:fred, :request]` telemetry span.
  See `Fred.Telemetry` for event names, measurements, and metadata.
  """

  @type params :: keyword() | map()
  @type response :: {:ok, map()} | {:error, Fred.Error.t()}

  @doc """
  Makes a GET request to the given FRED API endpoint.

  Automatically injects the API key, sets `file_type=json`, and emits
  telemetry events around the request.

  ## Parameters

    - `endpoint` — The API path, e.g. `"/series"` or `"/series/observations"`
    - `params` — A keyword list or map of query parameters

  ## Examples

      Fred.Client.get("/series", series_id: "GDP")
      Fred.Client.get("/series/observations", series_id: "UNRATE", limit: 10)
  """
  @spec get(String.t(), params()) :: response()
  def get(endpoint, params \\ []) do
    params =
      params
      |> normalize_params()
      |> Map.put(:api_key, Fred.api_key())
      |> Map.put(:file_type, "json")

    base_url = Fred.base_url()
    url = base_url <> endpoint
    timeout = Application.get_env(:fred, :recv_timeout, 30_000)
    metadata = Fred.Telemetry.build_metadata(endpoint, base_url, params)

    Fred.Telemetry.span(metadata, fn ->
      execute_request(url, params, timeout)
    end)
  end

  @doc """
  Same as `get/2` but raises on error.
  """
  @spec get!(String.t(), params()) :: map()
  def get!(endpoint, params \\ []) do
    case get(endpoint, params) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  @doc """
  Makes a GET request to an arbitrary URL with telemetry instrumentation.

  Used internally by `Fred.Maps` for the GeoFRED base URL. The `endpoint`
  and `base_url` are provided explicitly for telemetry metadata.

  ## Parameters

    - `url` — The full URL to request
    - `params` — A map of query parameters (should already include `:api_key`)
    - `endpoint` — The logical endpoint name for telemetry (e.g. `"/geofred/shapes/file"`)
    - `base_url` — The base URL for telemetry metadata
  """
  @spec get_raw(String.t(), map(), String.t(), String.t()) :: response()
  def get_raw(url, params, endpoint, base_url) do
    timeout = Application.get_env(:fred, :recv_timeout, 30_000)
    metadata = Fred.Telemetry.build_metadata(endpoint, base_url, params)

    Fred.Telemetry.span(metadata, fn ->
      execute_request(url, params, timeout)
    end)
  end

  # Shared request execution used by both `get/2` and `get_raw/4`.
  defp execute_request(url, params, timeout) do
    case Req.get(url, params: params, receive_timeout: timeout) do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        case JSON.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, Fred.Error.new(:parse_error, "Failed to parse JSON response")}
        end

      {:ok, %Req.Response{status: status, body: body}} when is_map(body) ->
        message = body["error_message"] || "HTTP #{status}"
        {:error, Fred.Error.new(:api_error, message, status)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, Fred.Error.new(:api_error, "HTTP #{status}: #{inspect(body)}", status)}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, Fred.Error.new(:transport_error, "Transport error: #{inspect(reason)}")}

      {:error, exception} ->
        {:error, Fred.Error.new(:request_error, "Request failed: #{inspect(exception)}")}
    end
  end

  # Normalize params: convert keyword list to map, remove nil values,
  # convert Date/DateTime to strings, convert lists to comma-separated strings.
  defp normalize_params(params) do
    params
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {k, serialize_value(v)} end)
    |> Map.new()
  end

  defp serialize_value(%Date{} = date), do: Date.to_iso8601(date)
  defp serialize_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp serialize_value(list) when is_list(list), do: Enum.join(list, ",")
  defp serialize_value(value), do: value
end
