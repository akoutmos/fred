defmodule Fred.Geo do
  @moduledoc """
  Optional integration with the [`geo`](https://hex.pm/packages/geo) library.

  When the `geo` package is installed, this module provides functions to convert
  raw GeoJSON maps (as returned by `Fred.Maps.shapes/2`) into native `Geo` structs
  like `%Geo.MultiPolygon{}`, `%Geo.Polygon{}`, etc.

  ## Installation

  Add `geo` to your dependencies alongside `fred`:

      defp deps do
        [
          {:fred, "~> 0.1.0"},
          {:geo, "~> 3.6 or ~> 4.0"}
        ]
      end

  ## Usage

  Convert a shapes response into Geo structs:

      {:ok, geojson} = Fred.Maps.shapes("state")
      {:ok, features} = Fred.Geo.decode(geojson)

      Enum.each(features, fn feature ->
        IO.inspect(feature.geometry, label: feature.properties["name"])
      end)

  Or use the shorthand that fetches and decodes in one step:

      {:ok, features} = Fred.Maps.shapes("state", decode: :geo)

  ## Without the `geo` library

  If `geo` is not installed, calling any function in this module returns
  `{:error, :geo_not_available}` with a helpful message. The rest of the
  Fred library works normally — shapes are returned as plain maps.
  """

  @doc """
  Decodes a GeoJSON map into Geo structs.

  Accepts any GeoJSON object: a `FeatureCollection`, a single `Feature`,
  or a bare geometry (`Point`, `Polygon`, `MultiPolygon`, etc.).

  ## Parameters

    - `geojson` — A decoded GeoJSON map (as returned by `Fred.Maps.shapes/2`
      or any GeoFRED endpoint)

  ## Returns

    - `{:ok, result}` — Where `result` is:
      - A list of `%Geo.Feature{}` structs for a `FeatureCollection`
      - A single `%Geo.Feature{}` for a `Feature`
      - A geometry struct (`%Geo.MultiPolygon{}`, etc.) for a bare geometry
    - `{:error, :geo_not_available}` — The `geo` library is not installed
    - `{:error, reason}` — Decoding failed

  ## Example

      {:ok, geojson} = Fred.Maps.shapes("state")
      {:ok, features} = Fred.Geo.decode(geojson)

      hd(features).geometry
      #=> %Geo.MultiPolygon{coordinates: [...], srid: 4326}

      hd(features).properties
      #=> %{"name" => "Alabama", ...}
  """
  @spec decode(map()) :: {:ok, term()} | {:error, term()}
  def decode(geojson) when is_map(geojson) do
    Geo.JSON.decode(geojson)
  end

  @doc """
  Same as `decode/1` but raises on error.
  """
  @spec decode!(map()) :: term()
  def decode!(geojson) when is_map(geojson) do
    case decode(geojson) do
      {:ok, result} -> result
      {:error, reason} -> raise ArgumentError, "Failed to decode GeoJSON: #{inspect(reason)}"
    end
  end
end
