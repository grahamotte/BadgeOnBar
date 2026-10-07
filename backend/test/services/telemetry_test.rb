require "test_helper"

class TelemetryTest < ActiveSupport::TestCase
  ENDPOINT = "https://otlp.example.test/otlp/v1/logs"

  def setup
    super
    @exporter = OpenTelemetry::SDK::Logs::Export::InMemoryLogRecordExporter.new
    @provider = Telemetry.build_provider(@exporter)
    @logger = Telemetry.logger(@provider)
  end

  def teardown
    @provider.shutdown
    super
  end

  def test_disabled_in_test
    previous = Telemetry::KEYS.index_with { |key| ENV[key] }
    Telemetry::KEYS.each { |key| ENV[key] = "value" }

    refute Telemetry.enabled?
    assert_nil Telemetry.start
    assert_nil Telemetry.provider
  ensure
    previous.each { |key, value| ENV[key] = value }
  end

  def test_severities
    @logger.level = Logger::DEBUG
    @logger.debug("debug")
    @logger.info("info")
    @logger.warn("warn")
    @logger.error("error")
    @logger.fatal("fatal")
    @logger.unknown("unknown")

    assert_equal(
      [ [ "DEBUG", 5 ], [ "INFO", 9 ], [ "WARN", 13 ], [ "ERROR", 17 ], [ "FATAL", 21 ], [ "ANY", 0 ] ],
      records.map { |x| [ x.severity_text, x.severity_number ] },
    )
  end

  def test_broadcast_keeps_tags_and_runs_blocks_once
    io = StringIO.new
    primary = ActiveSupport::TaggedLogging.logger(io)
    broadcast = ActiveSupport::BroadcastLogger.new(primary, Telemetry.logger(@provider, primary))
    runs = 0

    broadcast.tagged("request-1") do
      runs += 1
      broadcast.info("hello\n")
    end
    broadcast.info("worker") { "done" }

    assert_equal 1, runs
    assert_equal [ "[request-1] hello", "worker done" ], records.map(&:body)
    assert_equal [ "[request-1] hello", "done" ], io.string.lines.map(&:strip).compact_blank
  end

  def test_attributes
    Telemetry.with_attributes("a" => "1") do
      Telemetry.with_attributes("b" => "2") { @logger.info("nested") }
      @logger.info("outer")
    end
    @logger.info("none")

    assert_equal [ { "a" => "1", "b" => "2" }, { "a" => "1" }, nil ], records.map(&:attributes)
    assert_equal({}, Telemetry.attributes)
  end

  def test_resource
    previous = ENV["OTEL_SERVICE_NAME"]
    ENV["OTEL_SERVICE_NAME"] = "MOTO"
    attributes = Telemetry.resource.attribute_enumerator.to_h

    assert_equal "MOTO-dev", attributes.fetch("service.name")
    assert_equal "MOTO-dev", Telemetry.service_name
    assert_equal "test", attributes.fetch("deployment.environment")
    assert_equal "rails", attributes.fetch("service.instance.id")
    assert_equal "rails", Telemetry.role
  ensure
    ENV["OTEL_SERVICE_NAME"] = previous
  end

  def test_exporter_posts_protobuf_with_basic_auth
    stub_request(:post, ENDPOINT)
      .with(headers: { "Authorization" => "Basic abc", "Content-Type" => "application/x-protobuf" })
      .to_return(status: 200, body: "")
    exporter = Telemetry::Exporter.new(endpoint: ENDPOINT, headers: "Authorization=Basic abc")
    provider = Telemetry.build_provider(exporter)

    Telemetry.logger(provider).error("boom")

    assert_equal OpenTelemetry::SDK::Logs::Export::SUCCESS, provider.force_flush
    assert_requested :post, ENDPOINT, times: 1
  ensure
    provider&.shutdown
  end

  def test_exporter_failure_does_not_raise
    previous = OpenTelemetry.logger
    OpenTelemetry.logger = Logger.new(nil)
    stub_request(:post, ENDPOINT).to_return(status: 400, body: "")
    exporter = Telemetry::Exporter.new(endpoint: ENDPOINT, headers: "Authorization=Basic%20abc")
    provider = Telemetry.build_provider(exporter)

    Telemetry.logger(provider).error("boom")

    assert_equal OpenTelemetry::SDK::Logs::Export::FAILURE, provider.force_flush
  ensure
    provider&.shutdown
    OpenTelemetry.logger = previous
  end

  private

  def records
    @provider.force_flush
    @exporter.emitted_log_records
  end
end
