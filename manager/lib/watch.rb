class Watch
  class << self
    def call
      Trigger.call
    rescue Faraday::Error => error
      puts error.full_message
    end
  end
end
