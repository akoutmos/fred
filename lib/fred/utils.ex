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

  @doc false
  def generate_schema(fields) do
    fields
    |> Enum.flat_map(fn field ->
      generate_field_spec(field)
    end)
    |> Enum.sort_by(fn {field, _spec} ->
      field
    end)
    |> NimbleOptions.new!()
  end

  defp generate_field_spec(:realtime_range) do
    [
      realtime_start: [
        doc: "Start of the real-time period.",
        type: {:struct, Date}
      ],
      realtime_end: [
        doc: "End of the real-time period.",
        type: {:struct, Date}
      ]
    ]
  end

  defp generate_field_spec({:pagination, limit}) do
    [
      limit: [
        doc: "Max results (between 1-#{limit}).",
        type: {:custom, __MODULE__, :validate_range, [1..limit]},
        type_doc: "`t:pos_integer/0`"
      ],
      offset: [
        doc: "Result offset.",
        type: :pos_integer
      ]
    ]
  end

  defp generate_field_spec({:order_by, sortable_fields}) do
    [
      order_by: [
        doc: "Order the results by the provided field. #{generate_in_doc_list(sortable_fields)}",
        type: {:in, sortable_fields},
        type_doc: "`t:atom/0`"
      ],
      sort_order: [
        doc: "The sort order of the results. #{generate_in_doc_list([:asc, :desc])}",
        type: {:in, [:asc, :desc]},
        type_doc: "`t:atom/0`"
      ]
    ]
  end

  defp generate_field_spec(:tag_names) do
    [
      tag_names: [
        doc: "Semicolon-delimited tag names to match.",
        type: :string
      ],
      exclude_tag_names: [
        doc: "Semicolon-delimited tag names to exclude.",
        type: :string
      ]
    ]
  end

  defp generate_field_spec(:filter_variable_value) do
    [
      filter_variable: [
        doc: "The attribute to filter results by. #{generate_in_doc_list([:frequency, :units, :seasonal_adjustment])}",
        type: {:in, [:frequency, :units, :seasonal_adjustment]},
        type_doc: "`t:atom/0`"
      ],
      filter_value: [
        doc:
          "The value of the filter_variable attribute to filter results by. This requires that the `:filter_variable` is also provided.",
        type: :string
      ]
    ]
  end

  def validate_range(value, range) do
    if is_integer(value) and value in range do
      {:ok, value}
    else
      {:error, "expected an integer in #{inspect(range)}, got: #{inspect(value)}"}
    end
  end

  defp generate_in_doc_list(sortable_fields) do
    value_list =
      sortable_fields
      |> Enum.map_join("\n", fn field ->
        "- `#{inspect(field)}`"
      end)

    "Supported values are:\n#{value_list}"
  end
end
