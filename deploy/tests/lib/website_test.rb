require_relative "../test_helper"

class WebsiteTest < Minitest::Test
  def setup
    super
    @env = ENV.to_h.slice("CLOUDFLARE_API_TOKEN", "CLOUDFLARE_ACCOUNT_ID")
    @checkout = Dir.mktmpdir
    Website.checkout = @checkout
  end

  def teardown
    %w[CLOUDFLARE_API_TOKEN CLOUDFLARE_ACCOUNT_ID].each { |key| ENV[key] = @env[key] }
    FileUtils.rm_rf(@checkout)
    Website.checkout = nil
    super
  end

  def test_paths
    Website.checkout = nil

    assert_equal File.join(Constants.local_root, "deploy", "tmp", "website"), Website.checkout
    assert_equal File.join(Constants.local_root, "deploy", "tmp", "website", "website"), Website.root
  end

  def test_wrangler_config
    assert_equal(
      {
        name: "example-com",
        compatibility_date: Website::COMPATIBILITY_DATE,
        assets: { directory: "./dist", not_found_handling: "404-page" },
        routes: [
          { pattern: "example.com", custom_domain: true },
          { pattern: "www.example.com", custom_domain: true },
        ],
      },
      Website.wrangler_config,
    )
  end

  def test_deploy
    root = File.join(@checkout, "website")
    FileUtils.mkdir_p(root)
    Req.expects(:call).with(has_entry(:url, "https://api.cloudflare.com/client/v4/zones"))
      .returns(result: [ { name: "example.com", id: "zone", account: { id: "account" } } ])
      .twice
    Req.expects(:call).with(has_entry(:url, "https://api.cloudflare.com/client/v4/zones/zone/dns_records"))
      .returns(result: [
        { id: "apex", name: "example.com", type: "A", proxied: false },
        { id: "worker", name: "www.example.com", type: "AAAA", proxied: true },
        { id: "mail", name: "example.com", type: "MX", proxied: false },
        { id: "app", name: "app.example.com", type: "A", proxied: false },
      ])
    Req.expects(:call).with(has_entries(method: :delete, url: "https://api.cloudflare.com/client/v4/zones/zone/dns_records/apex"))
    commands = sequence("commands")
    Cmd.expects(:local).with("git fetch origin master").in_sequence(commands)
    Cmd.expects(:local).with("git rev-parse origin/master").returns("abc123\n").in_sequence(commands)
    Cmd.expects(:local).with("rm -rf ?", @checkout).in_sequence(commands)
    Cmd.expects(:local).with("git worktree prune").in_sequence(commands)
    Cmd.expects(:local).with("git worktree add --detach ? ?", @checkout, "abc123").in_sequence(commands)
    Cmd.expects(:local).with("cd ? && pnpm install --frozen-lockfile && pnpm exec astro build", root).in_sequence(commands)
    Cmd.expects(:local).with("cd ? && pnpm exec wrangler deploy", root).in_sequence(commands)

    Website.deploy

    assert_equal "cloudflare-token", ENV["CLOUDFLARE_API_TOKEN"]
    assert_equal "account", ENV["CLOUDFLARE_ACCOUNT_ID"]
    assert_equal(
      JSON.parse(JSON.generate(Website.wrangler_config)),
      JSON.parse(File.read(File.join(root, "wrangler.json"))),
    )
  end

  def test_deploy_creates_missing_zone
    FileUtils.mkdir_p(Website.root)
    Cmd.stubs(:local).returns("abc123\n")
    Req.expects(:call).with do |options|
      options[:url] == "https://api.cloudflare.com/client/v4/zones" && options[:method].blank?
    end.times(3).returns(
      { result: [] },
      { result: [ { name: "example.com", id: "zone", account: { id: "account" } } ] },
      { result: [ { name: "example.com", id: "zone", account: { id: "account" } } ] },
    )
    Req.expects(:call).with(has_entries(method: :post, url: "https://api.cloudflare.com/client/v4/zones"))
    Req.expects(:call).with(has_entry(:url, "https://api.cloudflare.com/client/v4/zones/zone/dns_records"))
      .returns(result: [])

    Website.deploy
  end

  def test_deploy_requires_website
    Subdomains.instance_variable_set(:@all, [ { name: "app", subdomains: [ "app" ], source: "frontend", directory: "frontend/subdomains/app" } ])

    assert_raises(RuntimeError) { Website.deploy }
  end
end
