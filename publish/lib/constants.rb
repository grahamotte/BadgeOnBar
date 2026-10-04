class Constants
  class << self
    attr_writer :config_path, :global_path

    def local_root = File.dirname(File.dirname(File.dirname(__FILE__)))
    def config_path = @config_path || File.join(local_root, "config.json")
    def config = @config ||= JSON.parse(File.read(config_path), symbolize_names: true)
    def global_path = @global_path || File.expand_path("~/.config/codemoto/config.json")

    def github_token
      global = File.file?(global_path) ? JSON.parse(File.read(global_path), symbolize_names: true) : {}
      raise "Code Moto global config must be an object: #{global_path}" unless global.is_a?(Hash)

      token = global[:githubToken]
      raise "Set githubToken in #{global_path}" unless token.is_a?(String) && token.present?

      token
    rescue JSON::ParserError
      raise "Invalid JSON in Code Moto global config: #{global_path}"
    end

    def github_repo = config.fetch(:githubRepo, "")
  end
end
