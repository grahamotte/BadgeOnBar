require_relative "../test_helper"

class ConstantsTest < Minitest::Test
  def test_config_values
    assert_equal File.join(@publish_test_dir, "config.json"), Constants.config_path
    assert_equal "git@github.com:example/app.git", Constants.github_repo
  end

  def test_missing_github_repo
    File.write(Constants.config_path, JSON.generate(domain: "example.com"))
    Constants.instance_variable_set(:@config, nil)

    assert_equal "", Constants.github_repo
  end

  def test_github_token_comes_only_from_global_config
    Constants.config[:githubToken] = "local-token"
    assert_equal "github-token", Constants.github_token

    File.write(Constants.global_path, JSON.generate({}))
    error = assert_raises(RuntimeError) { Constants.github_token }
    assert_equal "Set githubToken in #{Constants.global_path}", error.message
  end

  def test_invalid_global_config_is_rejected_without_exposing_contents
    [ "[1]", "{secret" ].each do |contents|
      File.write(Constants.global_path, contents)
      error = assert_raises(RuntimeError) { Constants.github_token }
      refute_includes error.message, "secret"
    end
  end

  def test_default_config_path
    Constants.config_path = nil

    assert_equal File.join(Constants.local_root, "config.json"), Constants.config_path
  end
end
