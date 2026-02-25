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

  describe "build_metadata/2" do
    test "builds metadata with redacted api_key" do
      params = [series_id: "GDP", api_key: "secret123", file_type: "json"]
      meta = Fred.Telemetry.build_metadata("https://api.stlouisfed.org/fred/series", params)

      assert meta.url == "https://api.stlouisfed.org/fred/series"
      assert meta.params == [series_id: "GDP", file_type: "json"]
      refute Keyword.has_key?(meta.params, :api_key)
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
