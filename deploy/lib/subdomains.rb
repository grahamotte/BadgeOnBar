class Subdomains
  class << self
    def all
      @all ||= Constants.config.fetch(:subdomains)
    end

    def droplet
      all.reject { |subdomain| subdomain[:website].present? }
    end

    def droplet?
      droplet.present?
    end

    def require_droplet!
      raise "config.json has no droplet subdomains; deploy the website with `mise deploy:website`" unless droplet?
    end

    def websites
      all.select { |subdomain| subdomain[:website].present? }
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

    def frontends
      droplet.select { |subdomain| subdomain[:directory].present? }
    end

    def dist(subdomain)
      File.join(Constants.remote_root, "frontend", "dist", subdomain.fetch(:name))
    end
  end
end
