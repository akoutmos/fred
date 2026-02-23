defmodule Fred.ClientTest do
  use ExUnit.Case, async: true

  describe "Fred.api_key/0" do
    test "raises when no key configured" do
      original = Application.get_env(:fred, :api_key)
      Application.put_env(:fred, :api_key, nil)
      System.delete_env("FRED_API_KEY")

      assert_raise RuntimeError, ~r/No FRED API key configured/, fn ->
        Fred.api_key()
      end

      if original, do: Application.put_env(:fred, :api_key, original)
    end

    test "reads key from application config" do
      Application.put_env(:fred, :api_key, "test_key_12345")
      assert Fred.api_key() == "test_key_12345"
    end
  end

  describe "Fred.base_url/0" do
    test "returns default base URL" do
      Application.delete_env(:fred, :base_url)
      assert Fred.base_url() == "https://api.stlouisfed.org/fred"
    end

    test "returns configured base URL" do
      Application.put_env(:fred, :base_url, "https://custom.api.example.com")
      assert Fred.base_url() == "https://custom.api.example.com"
      Application.delete_env(:fred, :base_url)
    end
  end
end

defmodule Fred.ErrorTest do
  use ExUnit.Case, async: true

  test "message/1 without status" do
    error = Fred.Error.new(:parse_error, "bad json")
    assert Exception.message(error) == "bad json"
  end

  test "message/1 with status" do
    error = Fred.Error.new(:api_error, "Not Found", 404)
    assert Exception.message(error) == "(404) Not Found"
  end
end

defmodule Fred.TelemetryTest do
  use ExUnit.Case, async: true

  describe "build_metadata/3" do
    test "builds metadata with redacted api_key" do
      params = %{series_id: "GDP", api_key: "secret123", file_type: "json"}
      meta = Fred.Telemetry.build_metadata("/series", "https://api.stlouisfed.org/fred", params)

      assert meta.endpoint == "/series"
      assert meta.base_url == "https://api.stlouisfed.org/fred"
      assert meta.params == %{series_id: "GDP", file_type: "json"}
      refute Map.has_key?(meta.params, :api_key)
    end
  end

  describe "span/2" do
    test "emits start and stop events on success" do
      ref = make_ref()
      parent = self()

      :telemetry.attach_many(
        "test-span-ok-#{inspect(ref)}",
        [[:fred, :request, :start], [:fred, :request, :stop]],
        fn event, measurements, metadata, _config ->
          send(parent, {ref, event, measurements, metadata})
        end,
        nil
      )

      metadata = %{endpoint: "/test", base_url: "http://test", params: %{}}

      result =
        Fred.Telemetry.span(metadata, fn ->
          {:ok, %{"data" => "value"}}
        end)

      assert result == {:ok, %{"data" => "value"}}

      assert_receive {^ref, [:fred, :request, :start], %{system_time: _}, %{endpoint: "/test"}}

      assert_receive {^ref, [:fred, :request, :stop], %{duration: duration},
                      %{endpoint: "/test", status: 200, result: :ok}}

      assert is_integer(duration) and duration >= 0

      :telemetry.detach("test-span-ok-#{inspect(ref)}")
    end

    test "emits start and stop events on error" do
      ref = make_ref()
      parent = self()

      :telemetry.attach(
        "test-span-err-#{inspect(ref)}",
        [:fred, :request, :stop],
        fn event, measurements, metadata, _config ->
          send(parent, {ref, event, measurements, metadata})
        end,
        nil
      )

      metadata = %{endpoint: "/test", base_url: "http://test", params: %{}}

      error = Fred.Error.new(:api_error, "Bad Request", 400)

      result =
        Fred.Telemetry.span(metadata, fn ->
          {:error, error}
        end)

      assert {:error, ^error} = result

      assert_receive {^ref, [:fred, :request, :stop], %{duration: _},
                      %{endpoint: "/test", status: 400, result: :error, error: ^error}}

      :telemetry.detach("test-span-err-#{inspect(ref)}")
    end

    test "emits exception event when function raises" do
      ref = make_ref()
      parent = self()

      :telemetry.attach(
        "test-span-exc-#{inspect(ref)}",
        [:fred, :request, :exception],
        fn event, measurements, metadata, _config ->
          send(parent, {ref, event, measurements, metadata})
        end,
        nil
      )

      metadata = %{endpoint: "/test", base_url: "http://test", params: %{}}

      assert_raise RuntimeError, "boom", fn ->
        Fred.Telemetry.span(metadata, fn ->
          raise "boom"
        end)
      end

      assert_receive {^ref, [:fred, :request, :exception], %{duration: _},
                      %{endpoint: "/test", kind: :error, reason: %RuntimeError{message: "boom"}}}

      :telemetry.detach("test-span-exc-#{inspect(ref)}")
    end
  end
end

defmodule Fred.Telemetry.LoggerTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  describe "attach/1 and detach/1" do
    test "attaches and detaches without error" do
      assert :ok = Fred.Telemetry.Logger.attach(handler_id: "test-attach-detach")
      assert :ok = Fred.Telemetry.Logger.detach("test-attach-detach")
    end

    test "returns error when attaching duplicate handler_id" do
      assert :ok = Fred.Telemetry.Logger.attach(handler_id: "test-dup")
      assert {:error, :already_exists} = Fred.Telemetry.Logger.attach(handler_id: "test-dup")
      Fred.Telemetry.Logger.detach("test-dup")
    end
  end

  describe "handle_event/4 for :stop" do
    test "logs successful request" do
      Fred.Telemetry.Logger.attach(handler_id: "test-log-ok", level: :info)

      log =
        capture_log(fn ->
          :telemetry.execute(
            [:fred, :request, :stop],
            %{duration: System.convert_time_unit(150, :millisecond, :native)},
            %{
              endpoint: "/series/observations",
              base_url: "https://api.stlouisfed.org/fred",
              params: %{series_id: "UNRATE", frequency: "m"},
              status: 200,
              result: :ok
            }
          )

          # Give logger a moment to flush
          Process.sleep(50)
        end)

      assert log =~ "[fred] GET /series/observations"
      assert log =~ "200"
      assert log =~ "series_id"

      Fred.Telemetry.Logger.detach("test-log-ok")
    end

    test "logs error request" do
      Fred.Telemetry.Logger.attach(handler_id: "test-log-err", level: :info)

      error = Fred.Error.new(:api_error, "Bad Request", 400)

      log =
        capture_log(fn ->
          :telemetry.execute(
            [:fred, :request, :stop],
            %{duration: System.convert_time_unit(83, :millisecond, :native)},
            %{
              endpoint: "/series",
              base_url: "https://api.stlouisfed.org/fred",
              params: %{series_id: ""},
              status: 400,
              result: :error,
              error: error
            }
          )

          Process.sleep(50)
        end)

      assert log =~ "[fred] GET /series"
      assert log =~ "error"
      assert log =~ "Bad Request"

      Fred.Telemetry.Logger.detach("test-log-err")
    end

    test "logs exception event" do
      Fred.Telemetry.Logger.attach(handler_id: "test-log-exc", level: :info)

      log =
        capture_log(fn ->
          :telemetry.execute(
            [:fred, :request, :exception],
            %{duration: System.convert_time_unit(5000, :millisecond, :native)},
            %{
              endpoint: "/series/observations",
              base_url: "https://api.stlouisfed.org/fred",
              params: %{series_id: "GDP"},
              kind: :error,
              reason: %RuntimeError{message: "connection reset"},
              stacktrace: []
            }
          )

          Process.sleep(50)
        end)

      assert log =~ "[fred] GET /series/observations"
      assert log =~ "exception"
      assert log =~ "connection reset"

      Fred.Telemetry.Logger.detach("test-log-exc")
    end
  end

  describe "format_params" do
    test "omits params section when empty" do
      Fred.Telemetry.Logger.attach(handler_id: "test-empty-params", level: :info)

      log =
        capture_log(fn ->
          :telemetry.execute(
            [:fred, :request, :stop],
            %{duration: System.convert_time_unit(50, :millisecond, :native)},
            %{
              endpoint: "/releases",
              base_url: "https://api.stlouisfed.org/fred",
              params: %{},
              status: 200,
              result: :ok
            }
          )

          Process.sleep(50)
        end)

      assert log =~ "[fred] GET /releases"
      refute log =~ "params:"

      Fred.Telemetry.Logger.detach("test-empty-params")
    end

    test "strips file_type from displayed params" do
      Fred.Telemetry.Logger.attach(handler_id: "test-strip-ft", level: :info)

      log =
        capture_log(fn ->
          :telemetry.execute(
            [:fred, :request, :stop],
            %{duration: System.convert_time_unit(50, :millisecond, :native)},
            %{
              endpoint: "/series",
              base_url: "https://api.stlouisfed.org/fred",
              params: %{series_id: "GDP", file_type: "json"},
              status: 200,
              result: :ok
            }
          )

          Process.sleep(50)
        end)

      assert log =~ "series_id"
      refute log =~ "file_type"

      Fred.Telemetry.Logger.detach("test-strip-ft")
    end
  end
end

defmodule Fred.GeoTest do
  use ExUnit.Case, async: true

  @sample_feature_collection %{
    "type" => "FeatureCollection",
    "features" => [
      %{
        "type" => "Feature",
        "properties" => %{"name" => "Test Region", "code" => 1},
        "geometry" => %{
          "type" => "Polygon",
          "coordinates" => [
            [[-90.0, 38.0], [-89.0, 38.0], [-89.0, 39.0], [-90.0, 39.0], [-90.0, 38.0]]
          ]
        }
      },
      %{
        "type" => "Feature",
        "properties" => %{"name" => "Another Region", "code" => 2},
        "geometry" => %{
          "type" => "Point",
          "coordinates" => [-90.0, 38.6]
        }
      }
    ]
  }

  describe "when geo library is available" do
    @describetag :geo_available

    test "decode/1 decodes a FeatureCollection" do
      assert {:ok, features} = Fred.Geo.decode(@sample_feature_collection)
      assert is_list(features)
      assert length(features) == 2
    end

    test "decode/1 decodes a single geometry" do
      geom = %{"type" => "Point", "coordinates" => [-90.0, 38.6]}
      assert {:ok, point} = Fred.Geo.decode(geom)
      assert point.__struct__ == Geo.Point
    end

    test "decode!/1 returns structs directly" do
      features = Fred.Geo.decode!(@sample_feature_collection)
      assert is_list(features)
    end

    test "decode_geometries/1 extracts only geometry structs" do
      assert {:ok, geometries} = Fred.Geo.decode_geometries(@sample_feature_collection)
      assert length(geometries) == 2
    end

    test "encode/1 round-trips a geometry" do
      geom = %{"type" => "Point", "coordinates" => [-90.0, 38.6]}
      {:ok, decoded} = Fred.Geo.decode(geom)
      {:ok, encoded} = Fred.Geo.encode(decoded)
      assert encoded["type"] == "Point"
      assert encoded["coordinates"] == [-90.0, 38.6]
    end
  end

  describe "decode_geometries/1 with invalid input" do
    test "returns error for non-FeatureCollection" do
      assert {:error, :not_a_feature_collection} =
               Fred.Geo.decode_geometries(%{"type" => "Point"})
    end
  end
end
