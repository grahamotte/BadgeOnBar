class Agent
  ROOT = File.expand_path("../..", __dir__)
  URL = "http://127.0.0.1:57123"

  class << self
    def start(prompt, directory: ROOT, model: nil, variant: nil)
      case ENV.fetch("AGENT_RUNNER")
      when "openchamber"
        openchamber(prompt, directory, model:, variant:)
      else
        raise "Unknown AGENT_RUNNER #{ENV.fetch("AGENT_RUNNER")}"
      end
    end

    def openchamber(prompt, directory, model:, variant:)
      model = ENV.fetch("AGENT_MODEL") if model.blank?
      variant = ENV["AGENT_VARIANT"] if variant.blank?
      payload = {
        directory:,
        prompt:,
        model:,
      }
      payload[:variant] = variant if variant.present?
      Req.call(
        url: "#{URL}/api/openchamber/sessions",
        method: :post,
        payload:,
      )
    end
  end
end
