class Subdomains
  SOURCES = %w[website frontend backend].freeze

  class << self
    def all
      @all ||= Constants.config.fetch(:subdomains).each do |subdomain|
        raise "config.json subdomain #{subdomain[:name]} has unknown source #{subdomain[:source].inspect}" unless SOURCES.include?(subdomain[:source])
      end
    end

    def from(source)
      all.select { |subdomain| subdomain.fetch(:source) == source }
    end

    def droplet
      all.reject { |subdomain| subdomain.fetch(:source) == "website" }
    end

    def droplet?
      droplet.present?
    end

    def require_droplet!
      raise "config.json has no droplet subdomains; deploy the website with `mise deploy:website`" unless droplet?
    end

    def websites
      from("website")
    end

    def frontends
      from("frontend")
    end

    def domains(subdomain = nil)
      (subdomain.present? ? subdomain.fetch(:subdomains) : droplet.flat_map { |x| x.fetch(:subdomains) })
        .map { |x| x.present? ? "#{x}.#{Constants.domain}" : Constants.domain }
    end

    def website_domains
      websites.flat_map { |subdomain| domains(subdomain) }
    end

    def url(name)
      "https://#{domains(all.find { |subdomain| subdomain.fetch(:name) == name }).first}"
    end

    def dist(subdomain)
      File.join(Constants.remote_root, "frontend", "dist", subdomain.fetch(:name))
    end
  end
end
