require_relative "test_helper"

class SafetyTest < Minitest::Test
  def test_blocks_commands
    assert_raises(UnsafeTestOperation) { system("true") }
    assert_raises(UnsafeTestOperation) { `true` }
    assert_raises(UnsafeTestOperation) { Process.spawn("true") }
    assert_raises(UnsafeTestOperation) { IO.popen("true") }
    assert_raises(UnsafeTestOperation) { Cmd.local("true") }
  end

  def test_blocks_requests
    assert_raises(UnsafeTestOperation) { Req.call(url: "https://example.com") }
    assert_raises(WebMock::NetConnectNotAllowedError) { Faraday.get("https://example.com") }
    assert_raises(UnsafeTestOperation) { TCPSocket.new("example.com", 80) }
  end

  def test_patches_have_one_unit_test_file
    source_root = File.expand_path("../patches", __dir__)
    test_root = File.join(__dir__, "patches")
    sources = Dir[File.join(source_root, "**/*.rb")]
      .map { |path| path.delete_prefix("#{source_root}/").delete_suffix(".rb") }
      .sort
    tests = Dir[File.join(test_root, "**/*_test.rb")]
      .map { |path| path.delete_prefix("#{test_root}/").delete_suffix("_test.rb") }
      .sort

    assert_equal sources, tests
  end

  def test_unit_tests_only_mock_boundaries
    tests = Dir[File.join(__dir__, "**/*_test.rb")]
      .reject { |path| path.end_with?("safety_test.rb") }
      .map { |path| File.read(path) }
      .join("\n")

    refute_match(/\b(?!Cmd|Req)\w+\.(?:stubs|expects)\(/, tests)
  end
end
