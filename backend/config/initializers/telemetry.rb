Rails.application.config.after_initialize do
  Telemetry.start
  Rails.error.subscribe(ErrorLogger.new)
end
