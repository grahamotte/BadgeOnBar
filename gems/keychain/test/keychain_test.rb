# frozen_string_literal: true

require_relative "test_helper"

class KeychainTest < Minitest::Test
  class FakeSecurity
    attr_accessor :search, :default, :login, :failures
    attr_reader :calls

    def initialize(search:, default:, login:)
      @search = search
      @default = default
      @login = login
      @failures = []
      @calls = []
    end

    def call(*arguments)
      @calls << arguments
      raise "security #{arguments.first} failed" if failures.include?(arguments.first) && arguments.include?("-s")

      command, *options = arguments
      values = options.include?("-s") ? options.drop(options.index("-s") + 1) : nil
      case command
      when "list-keychains"
        return @search = values if values

        search.map { |path| "    \"#{path}\"\n" }.join
      when "default-keychain"
        return @default = values.first if values

        default ? "    \"#{default}\"\n" : ""
      when "login-keychain"
        return @login = values.first if values

        login ? "    \"#{login}\"\n" : ""
      end
    end
  end

  def setup
    @home = Dir.mktmpdir("keychain-home")
    @keychains = File.join(@home, "Library", "Keychains")
    FileUtils.mkdir_p(@keychains)
    @login = write_keychain("login.keychain-db", "login")
    @system = write_keychain("System.keychain", "system")
    @worktree = File.join(@home, "Code", "repo-moto-1")
    FileUtils.mkdir_p(@worktree)
    @temporary = File.join(@worktree, "publish", "tmp", "signing.keychain-db")
    FileUtils.mkdir_p(File.dirname(@temporary))
    File.write(@temporary, "temporary")
    @security = FakeSecurity.new(search: [ @login, @system ], default: @login, login: @login)
    @keychain = Keychain.new(home: @home, runner: @security)
  end

  def teardown
    FileUtils.remove_entry(@home)
  end

  def test_snapshots_search_list_default_and_login_keychains
    assert_equal({ search: [ @login, @system ], default: @login, login: @login }, @keychain.snapshot)
    assert_includes @security.calls, [ "list-keychains", "-d", "user" ]
    assert_includes @security.calls, [ "default-keychain", "-d", "user" ]
    assert_includes @security.calls, [ "login-keychain" ]
  end

  def test_snapshots_unset_keychains_as_nil
    @security.default = nil
    @security.login = nil

    assert_equal({ search: [ @login, @system ], default: nil, login: nil }, @keychain.snapshot)
  end

  def test_protect_restores_keychains_replaced_inside_the_block
    result = @keychain.protect do
      replace_with_temporary
      :done
    end

    assert_equal :done, result
    assert_healthy
    assert_empty Dir.glob(File.join(@keychain.state_root, "*.json"))
  end

  def test_protect_restores_keychains_when_the_block_raises
    assert_raises(RuntimeError) do
      @keychain.protect do
        replace_with_temporary
        raise "signing failed"
      end
    end

    assert_healthy
    assert_empty Dir.glob(File.join(@keychain.state_root, "*.json"))
  end

  def test_protect_restores_keychains_when_interrupted
    assert_raises(Interrupt) do
      @keychain.protect do
        replace_with_temporary
        raise Interrupt
      end
    end

    assert_healthy
  end

  def test_protect_skips_restore_when_unchanged
    @keychain.protect { }

    refute @security.calls.any? { |arguments| arguments.include?("-s") }
  end

  def test_protect_records_snapshot_while_running
    @keychain.protect do
      files = Dir.glob(File.join(@keychain.state_root, "*.json"))
      assert_equal 1, files.size
      state = JSON.parse(File.read(files.first), symbolize_names: true)
      assert_equal Process.pid, state[:pid]
      assert_equal({ search: [ @login, @system ], default: @login, login: @login }, state[:snapshot])
      assert @keychain.busy?
    end

    refute @keychain.busy?
  end

  def test_protect_keeps_snapshot_when_restore_fails
    @security.failures = [ "default-keychain" ]

    assert_raises(RuntimeError) do
      @keychain.protect { @security.search = [ @temporary ] }
    end

    assert_equal 1, Dir.glob(File.join(@keychain.state_root, "*.json")).size
    assert_equal [ @login, @system ], @security.search
  end

  def test_restore_falls_back_to_login_keychain_for_missing_keychains
    missing = File.join(@home, "gone.keychain-db")

    @keychain.restore(search: [ missing, @system ], default: missing, login: missing)

    assert_equal [ @login, @system ], @security.search
    assert_equal @login, @security.default
    assert_equal @login, @security.login
  end

  def test_restore_runs_every_step_before_raising
    @security.failures = [ "list-keychains" ]

    error = assert_raises(RuntimeError) do
      @keychain.restore(search: [ @login ], default: @login, login: @login)
    end

    assert_equal "security list-keychains failed", error.message
    assert_includes @security.calls, [ "default-keychain", "-d", "user", "-s", @login ]
    assert_includes @security.calls, [ "login-keychain", "-s", @login ]
  end

  def test_release_removes_keychains_inside_directory
    replace_with_temporary

    assert_equal [ @temporary ], @keychain.release(@worktree)

    assert_equal [ @login ], @security.search
    assert_equal @login, @security.default
    assert_equal @login, @security.login
  end

  def test_release_keeps_other_keychains_in_search_list
    @security.search = [ @temporary, @login, @system ]

    @keychain.release(@worktree)

    assert_equal [ @login, @system ], @security.search
    assert_equal @login, @security.default
  end

  def test_release_ignores_sibling_directories_with_matching_prefix
    sibling = File.join("#{@worktree}-other", "signing.keychain-db")
    FileUtils.mkdir_p(File.dirname(sibling))
    File.write(sibling, "sibling")
    @security.search = [ @login, sibling ]

    assert_empty @keychain.release(@worktree)
    assert_equal [ @login, sibling ], @security.search
  end

  def test_release_removes_missing_keychains_without_directory
    missing = File.join(@home, "deleted", "signing.keychain-db")
    @security.search = [ missing ]
    @security.default = missing

    assert_equal [ missing ], @keychain.release

    assert_equal [ @login ], @security.search
    assert_equal @login, @security.default
  end

  def test_release_does_nothing_when_healthy
    assert_empty @keychain.release(@worktree)
    refute @security.calls.any? { |arguments| arguments.include?("-s") }
  end

  def test_recover_restores_snapshots_from_dead_processes
    write_state(99_999_999, { search: [ @login, @system ], default: @login, login: @login })
    replace_with_temporary

    assert_equal 1, @keychain.recover.size

    assert_healthy
    assert_empty Dir.glob(File.join(@keychain.state_root, "*.json"))
  end

  def test_recover_restores_oldest_snapshot_last
    write_state(99_999_998, { search: [ @login ], default: @login, login: @login }, "20260101000000000000")
    write_state(99_999_999, { search: [ @temporary ], default: @temporary, login: @login }, "20260102000000000000")

    @keychain.recover

    assert_equal [ @login ], @security.search
    assert_equal @login, @security.default
  end

  def test_recover_leaves_snapshots_from_running_processes
    write_state(Process.pid, { search: [ @login ], default: @login, login: @login })
    replace_with_temporary

    assert_empty @keychain.recover

    assert_equal [ @temporary ], @security.search
    assert @keychain.busy?
  end

  def test_recover_discards_unreadable_snapshots
    FileUtils.mkdir_p(@keychain.state_root)
    File.write(File.join(@keychain.state_root, "broken.json"), "{")

    assert_empty @keychain.recover
    assert_empty Dir.glob(File.join(@keychain.state_root, "*.json"))
  end

  def test_problems_is_empty_when_healthy
    assert_empty @keychain.problems
  end

  def test_problems_reports_replaced_keychains
    replace_with_temporary

    assert_equal(
      [
        "default keychain is #{@temporary}, not #{@login}",
        "login keychain is #{@temporary}, not #{@login}",
        "search list does not include #{@login}",
      ],
      @keychain.problems,
    )
  end

  def test_problems_reports_unset_keychains
    @security.default = nil
    @security.login = nil

    assert_includes @keychain.problems, "default keychain is unset, not #{@login}"
    assert_includes @keychain.problems, "login keychain is unset, not #{@login}"
  end

  def test_problems_reports_missing_login_keychain
    File.delete(@login)

    assert_includes @keychain.problems, "#{@login} is missing"
  end

  def test_problems_reports_larger_renamed_login_keychain
    renamed = write_keychain("login_renamed_1.keychain-db", "original login keychain")

    assert_equal [ "#{renamed} is larger than #{@login} and may hold the original login keychain" ], @keychain.problems
  end

  def test_problems_ignores_restored_renamed_login_keychain
    write_keychain("login_renamed_1.keychain-db", "login")
    write_keychain("login_renamed_2.keychain-db", "new")

    assert_empty @keychain.problems
  end

  def test_problems_skips_check_while_protected_task_runs
    write_state(Process.pid, { search: [ @login ], default: @login, login: @login })
    replace_with_temporary

    assert_empty @keychain.problems
  end

  def test_repair_restores_largest_renamed_login_keychain
    write_keychain("login_renamed_1.keychain-db", "original login keychain")
    write_keychain("login_renamed_2.keychain-db", "smaller one")
    replace_with_temporary

    result = @keychain.repair

    assert_equal File.join(@keychains, "login_renamed_1.keychain-db"), result[:original]
    assert_equal "login", File.read(result[:backup])
    assert_equal "original login keychain", File.read(@login)
    assert_equal [ @login, @temporary ], @security.search
    assert_equal @login, @security.default
    assert_equal @login, @security.login
    assert_empty @keychain.problems
  end

  def test_repair_restores_renamed_keychain_when_login_is_missing
    File.delete(@login)
    write_keychain("login_renamed_1.keychain-db", "original")

    result = @keychain.repair

    assert_nil result[:backup]
    assert_equal "original", File.read(@login)
  end

  def test_repair_resets_keychains_without_renamed_file
    @security.default = @system

    assert_nil @keychain.repair

    assert_equal @login, @security.default
    assert_equal [ @login, @system ], @security.search
  end

  def test_repair_recovers_stale_snapshot_first
    write_state(99_999_999, { search: [ @login, @system ], default: @login, login: @login })
    replace_with_temporary

    @keychain.repair

    assert_equal [ @login, @system ], @security.search
    assert_empty Dir.glob(File.join(@keychain.state_root, "*.json"))
  end

  private

  def write_keychain(name, content)
    path = File.join(@keychains, name)
    File.write(path, content)
    path
  end

  def write_state(pid, snapshot, stamp = "20260101000000000000")
    FileUtils.mkdir_p(@keychain.state_root)
    File.write(File.join(@keychain.state_root, "#{stamp}-#{pid}.json"), JSON.generate(pid:, snapshot:))
  end

  def replace_with_temporary
    @security.search = [ @temporary ]
    @security.default = @temporary
    @security.login = @temporary
  end

  def assert_healthy
    assert_equal [ @login, @system ], @security.search
    assert_equal @login, @security.default
    assert_equal @login, @security.login
  end
end
