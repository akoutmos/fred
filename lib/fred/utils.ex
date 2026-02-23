defmodule Fred.Utils do
  @moduledoc false

  alias Fred.Error

  @doc false
  def validate_opts(opts, schema) do
    case NimbleOptions.validate(opts, schema) do
      {:ok, _validated_opts} ->
        :ok

      {:error, %NimbleOptions.ValidationError{} = error} ->
        message = Exception.message(error)
        {:error, Error.new(:option_error, message)}
    end
  end
end
