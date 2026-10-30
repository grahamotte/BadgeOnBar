class WebsitePatch < BasePatch
  class << self
    def always
      raise "config.json has no website subdomain" if Subdomains.websites.blank?

      Cmd.local("git fetch origin master")
      sha = Cmd.local("git rev-parse origin/master").strip
      puts "deploying website origin/master #{sha}"
      Cmd.local("rm -rf ?", Sources::Website.checkout)
      Cmd.local("git worktree prune")
      Cmd.local("git worktree add --detach ? ?", Sources::Website.checkout, sha)
      Cmd.local("cd ? && pnpm install --frozen-lockfile && pnpm exec astro build", Sources::Website.root)
      File.write(File.join(Sources::Website.root, "wrangler.json"), JSON.pretty_generate(Sources::Website.wrangler_config))

      Cloudflare.create_zone if Cloudflare.zone_id.blank?
      Cloudflare.current_dns_records.select { |x| Sources::Website.droplet_record?(x) }.each do |record|
        Cloudflare.delete_dns_record(record[:id])
      end

      ENV["CLOUDFLARE_API_TOKEN"] = Constants.cloudflare_token
      ENV["CLOUDFLARE_ACCOUNT_ID"] = Cloudflare.account_id
      Cmd.local("cd ? && pnpm exec wrangler deploy", Sources::Website.root)
    end
  end
end
