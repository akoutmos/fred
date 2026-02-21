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

  alias Fred.Error
  alias Fred.Telemetry
  alias Req.Response

  @type response :: {:ok, map()} | {:error, Error.t()}

  @api_host "api.stlouisfed.org/fred"
  @maps_host "api.stlouisfed.org/geofred"

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
  @spec get_json(endpoint :: String.t(), params :: keyword()) :: response()
  def get_json(endpoint, params \\ []) do
    params = Keyword.put(params, :file_type, "json")
    url = generate_url(@api_host, endpoint)

    url
    |> Telemetry.build_metadata(params)
    |> Telemetry.span(fn ->
      execute_request(url, params)
    end)
  end

  @doc """
  Makes a GET request to an arbitrary URL with telemetry instrumentation.

  Used internally by `Fred.Maps` for the GeoFRED base URL. The `endpoint`
  and `base_url` are provided explicitly for telemetry metadata.

  ## Parameters

    - `url` - The full URL to request
    - `params` - A map of query parameters (should already include `:api_key`)
    - `endpoint` - The logical endpoint name for telemetry (e.g. `"/geofred/shapes/file"`)
    - `base_url` - The base URL for telemetry metadata
  """
  @spec get_map_json(endpoint :: String.t(), params :: keyword()) :: response()
  def get_map_json(endpoint, params \\ []) do
    params = Keyword.put(params, :file_type, "json")
    url = generate_url(@maps_host, endpoint)

    url
    |> Telemetry.build_metadata(params)
    |> Telemetry.span(fn ->
      execute_request(url, params)
    end)
  end

  @doc """
  Docs coming soon
  """
  @spec get_map_raw(endpoint :: String.t(), params :: keyword()) :: response()
  def get_map_raw(endpoint, params \\ []) do
    url = generate_url(@maps_host, endpoint)

    url
    |> Telemetry.build_metadata(params)
    |> Telemetry.span(fn ->
      execute_request(url, params)
    end)
  end

  # Shared request execution used by both `get/2` and `get_raw/4`.
  defp execute_request(url, params) do
    with timeout <- Application.get_env(:fred, :timeout, 30_000),
         {:ok, params} <- prepare_params(params),
         {:ok, %Response{status: 200, body: body}} <- Req.get(url, params: params, receive_timeout: timeout) do
      {:ok, body}
    else
      {:ok, %Response{status: status, body: body}} ->
        {:error, Error.new(:api_error, "HTTP #{status}: #{inspect(body)}", status)}

      {:error, error_code, message} ->
        {:error, Error.new(error_code, "Library error: #{message}")}

      {:error, exception} ->
        {:error, Error.new(:request_error, "Request failed: #{inspect(exception)}")}
    end
  end

  defp prepare_params(params) do
    with {:ok, api_key} <- fetch_api_key() do
      prepared_params =
        params
        |> normalize_params()
        |> Map.put(:api_key, api_key)

      {:ok, prepared_params}
    end
  end

  defp normalize_params(params) do
    params
    |> Enum.reject(fn {_k, v} ->
      is_nil(v)
    end)
    |> Enum.map(fn {k, v} ->
      {k, serialize_value(v)}
    end)
    |> Map.new()
  end

  defp serialize_value(%Date{} = date), do: Date.to_iso8601(date)
  defp serialize_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp serialize_value(list) when is_list(list), do: Enum.join(list, ",")
  defp serialize_value(value), do: value

  defp generate_url(host, endpoint) do
    URI
    |> struct(scheme: "https", host: host, path: endpoint)
    |> URI.to_string()
  end

  defp fetch_api_key do
    case Application.get_env(:fred, :api_key) do
      nil ->
        {:error, :missing_api_key,
         """
         FRED API key has not been configured. Set one via your application configuration:

         config :fred,
           api_key: "YOUR_API_KEY"

         Register for a free key at:
         https://fred.stlouisfed.org/docs/api/api_key.html
         """}

      key ->
        {:ok, key}
    end
  end
end
