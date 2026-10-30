require_relative "../test_helper"

class SubdomainsTest < Minitest::Test
  def test_domains
    assert_equal(
      [ "example.com", "www.example.com" ],
      Subdomains.domains(subdomains: [ "", "www" ]),
    )
  end

  def test_all_frontends_domains_and_dist
    assert_equal [ "website", "app", "api", "hc", "jobs" ], Subdomains.all.map { |x| x[:name] }
    assert_equal [ "app", "hc" ], Subdomains.frontends.map { |x| x[:name] }
    assert_equal(
      [ "app.example.com", "api.example.com", "hc.example.com", "jobs.example.com" ],
      Subdomains.domains,
    )
    assert_equal "/var/www/example.com/frontend/dist/app", Subdomains.dist(Subdomains.frontends.first)
  end

  def test_websites
    assert_equal [ "website" ], Subdomains.websites.map { |x| x[:name] }
    assert_equal [ "app", "api", "hc", "jobs" ], Subdomains.droplet.map { |x| x[:name] }
    assert_equal [ "example.com", "www.example.com" ], Subdomains.website_domains
  end

  def test_url
    assert_equal "https://api.example.com", Subdomains.url("api")
    assert_equal "https://example.com", Subdomains.url("website")
  end

  def test_droplet
    assert Subdomains.droplet?
    Subdomains.require_droplet!

    Subdomains.instance_variable_set(:@all, [ { name: "website", subdomains: [ "" ], website: true } ])

    refute Subdomains.droplet?
    assert_raises(RuntimeError) { Subdomains.require_droplet! }
    assert_equal [], Subdomains.domains
  end
end
