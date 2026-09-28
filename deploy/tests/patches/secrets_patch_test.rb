require_relative "../test_helper"

class SecretsPatchTest < Minitest::Test
  def test_always_writes_each_environment_file_once
    writes = []
    Cmd.stubs(:ssh_write).with { |path, content, **| writes << [ path, content ]; true }

    SecretsPatch.always
    SecretsPatch.always

    content = File.read(Constants.local_env_path)
    assert_equal(
      [
        [ Constants.remote_env_path, content ],
        [ Constants.remote_env_prod_path, content ],
        [ File.join(Constants.remote_home_dir, ".env"), content ],
      ],
      writes,
    )
  end
end
