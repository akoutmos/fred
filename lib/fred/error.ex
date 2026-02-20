defmodule Fred.Error do
  @moduledoc """
  Structured error type for FRED API errors.

  ## Error Types

    - `:api_error` — The FRED API returned a non-200 status code
    - `:parse_error` — Failed to parse the API response
    - `:transport_error` — Network/connection error
    - `:request_error` — Other request failure
    - `:dependency_missing` — An optional dependency is not installed
  """

  @type error_type ::
          :api_error | :parse_error | :transport_error | :request_error | :dependency_missing

  @type t :: %__MODULE__{
          type: error_type(),
          message: String.t(),
          status: integer() | nil
        }

  defexception [:type, :message, :status]

  @doc false
  def new(type, message, status \\ nil) do
    %__MODULE__{type: type, message: message, status: status}
  end

  @impl true
  def message(%__MODULE__{message: message, status: nil}), do: message
  def message(%__MODULE__{message: message, status: status}), do: "(#{status}) #{message}"
end
