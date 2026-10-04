require_relative "test_helper"

class SettingsTest < Minitest::Test
  def test_reads_configured_path
    assert_equal "codemoto.org", Settings.all[:domain]
  end

  def test_memoizes_until_reset
    Settings.all
    File.write(Settings.path, JSON.generate(domain: "other.org"))

    assert_equal "codemoto.org", Settings.all[:domain]
  end

  def test_reset_restores_default_path
    Settings.reset

    assert_equal File.expand_path("../../config.json", __dir__), Settings.path
    assert Settings.all.key?(:domain)
  end

  def test_global_secrets_are_not_copied_into_local_settings
    write_global("1passwordServiceAccountToken": "private-token")
    File.write(Settings.path, JSON.generate(domain: "local.org"))

    assert_equal "local.org", Settings.all[:domain]
    refute Settings.all.key?(:"1passwordServiceAccountToken")
  end

  def test_missing_global_config_is_empty
    assert_equal({}, Settings.global)
  end

  def test_global_config_is_memoized_until_reset
    write_global("1passwordServiceAccountToken": "first")
    assert_equal "first", Settings.global[:"1passwordServiceAccountToken"]
    write_global("1passwordServiceAccountToken": "second")
    assert_equal "first", Settings.global[:"1passwordServiceAccountToken"]
    global_path = Settings.global_path
    Settings.reset
    Settings.global_path = global_path
    assert_equal "second", Settings.global[:"1passwordServiceAccountToken"]
  end

  def test_service_account_token_comes_from_global_config
    write_global("1passwordServiceAccountToken": "private-token")

    assert_equal "private-token", Settings.service_account_token
  end

  def test_missing_or_invalid_service_account_token_has_actionable_error
    [ nil, "", 42 ].each do |token|
      Settings.reset
      Settings.global_path = File.join(@manager_test_dir, "global-config.json")
      write_global("1passwordServiceAccountToken": token)

      error = assert_raises(RuntimeError) { Settings.service_account_token }
      assert_includes error.message, "Set 1passwordServiceAccountToken"
    end
  end

  def test_invalid_global_json_does_not_expose_contents
    File.write(Settings.global_path, '{"1passwordServiceAccountToken": "private-token", broken}')

    error = assert_raises(RuntimeError) { Settings.global }
    assert_includes error.message, Settings.global_path
    refute_includes error.message, "private-token"
  end

  def test_global_config_requires_an_object
    write_global([])

    error = assert_raises(RuntimeError) { Settings.global }
    assert_includes error.message, "must be an object"
  end

  def test_reset_restores_default_global_path
    Settings.reset

    assert_equal File.expand_path("~/.config/codemoto/config.json"), Settings.global_path
  end

  private

  def write_global(config)
    File.write(Settings.global_path, JSON.generate(config))
  end
end
