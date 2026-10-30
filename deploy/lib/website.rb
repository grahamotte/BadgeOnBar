class Website
  COMPATIBILITY_DATE = "2026-10-29"

  class << self
    attr_writer :checkout

    def checkout = @checkout || File.join(Constants.local_root, "deploy", "tmp", "website")
    def root = File.join(checkout, "website")

    def deploy
      raise "config.json has no website subdomain" if Subdomains.websites.blank?

      Cmd.local("git fetch origin master")
      sha = Cmd.local("git rev-parse origin/master").strip
      puts "deploying website origin/master #{sha}"
      Cmd.local("rm -rf ?", checkout)
      Cmd.local("git worktree prune")
      Cmd.local("git worktree add --detach ? ?", checkout, sha)
      Cmd.local("cd ? && pnpm install --frozen-lockfile && pnpm exec astro build", root)
      File.write(File.join(root, "wrangler.json"), JSON.pretty_generate(wrangler_config))

      Cloudflare.create_zone if Cloudflare.zone_id.blank?
      Cloudflare.current_dns_records.select { |x| droplet_record?(x) }.each do |record|
        Cloudflare.delete_dns_record(record[:id])
      end

      ENV["CLOUDFLARE_API_TOKEN"] = Constants.cloudflare_token
      ENV["CLOUDFLARE_ACCOUNT_ID"] = Cloudflare.account_id
      Cmd.local("cd ? && pnpm exec wrangler deploy", root)
    end

    def wrangler_config
      {
        name: Constants.domain.tr(".", "-"),
        compatibility_date: COMPATIBILITY_DATE,
        assets: { directory: "./dist", not_found_handling: "404-page" },
        routes: Subdomains.website_domains.map { |domain| { pattern: domain, custom_domain: true } },
      }
    end

    private

    def droplet_record?(record)
      Cloudflare.website_record?(record) && %w[A AAAA CNAME].include?(record[:type]) && !record[:proxied]
    end
  end
end
