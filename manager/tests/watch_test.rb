require_relative "test_helper"

class WatchTest < Minitest::Test
  def test_triggers_work_without_syncing_statuses
    calls = stub_watch(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
      ],
    )

    output, = capture_io { Watch.call }

    assert_equal "started working on MOTO-1\n", output
    assert calls.any? { |call| graphql?(call, "query Issues") }
    assert calls.any? { |call| call[:url].to_s.end_with?("/api/openchamber/sessions") }
    assert_empty calls.select { |call| graphql?(call, "mutation WorkflowState") }
    assert_empty calls.select { |call| graphql?(call, "mutation IssueLabelCreate") }
  end

  def test_logs_openchamber_http_errors_without_raising
    calls = stub_watch(
      items: [
        { id: "item-1", identifier: "MOTO-1", url: "https://linear.app/gotte/issue/MOTO-1", state: { id: "s-ready", name: "Ready" } },
      ],
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless opts[:url].to_s.end_with?("/api/openchamber/sessions")

      true
    end.raises(Faraday::ServerError.new("the server responded with status 500 for POST http://127.0.0.1:57123/api/openchamber/sessions"))

    output, = capture_io { Watch.call }

    assert_includes output, "the server responded with status 500 for POST http://127.0.0.1:57123/api/openchamber/sessions"
    refute_includes output, "started working on MOTO-1"
    inputs = calls.select { |call| graphql?(call, "mutation IssueUpdate") }.map { |call| call.dig(:payload, :variables, :input) }
    assert_equal [
      { stateId: "s-working" },
      { addedLabelIds: [ "l-working" ] },
      { removedLabelIds: [ "l-working" ] },
      { stateId: "s-ready" },
    ], inputs
  end

  def test_logs_linear_http_errors_without_raising
    Req.stubs(:call).raises(Faraday::ConnectionFailed.new("Failed to open TCP connection to api.linear.app"))

    output, = capture_io { Watch.call }

    assert_includes output, "Failed to open TCP connection to api.linear.app"
  end

  def test_reraises_non_http_errors
    Req.stubs(:call).raises("invalid token")

    error = assert_raises(RuntimeError) { Watch.call }

    assert_equal "invalid token", error.message
  end

  private

  def graphql?(opts, fragment)
    opts[:url] == Linear::HOST && opts.dig(:payload, :query).to_s.include?(fragment)
  end

  def stub_watch(items:)
    calls = []
    ok = Object.new
    ok.define_singleton_method(:success?) { true }
    Open3.stubs(:capture3).with do |*args, **_kwargs|
      if args[1] == "worktree" && args[2] == "add"
        path = args[3] == "-b" ? args[5] : args[3]
        FileUtils.mkdir_p(path)
      end
      true
    end.returns([ "", "", ok ])
    states = Linear::STATUSES.each_with_index.map do |status, index|
      position = index.to_f
      { id: "s-#{status[:name].downcase}", **status, position: }
    end
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless opts[:url].to_s.end_with?("/api/openchamber/sessions")

      calls << opts
      true
    end.returns({ sessionId: "ses-1" })
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query Workspace")

      calls << opts
      true
    end.returns(
      {
        data: {
          organization: { urlKey: "gotte" },
          teams: { nodes: [ { id: "team-1", key: "MOTO" } ] },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query States")

      calls << opts
      true
    end.returns(
      {
        data: {
          team: {
            states: {
              nodes: states,
            },
          },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query Issues")

      calls << opts
      true
    end.returns(
      {
        data: {
          team: {
            issues: {
              nodes: items,
              pageInfo: { hasNextPage: false, endCursor: nil },
            },
          },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "query Tags")

      calls << opts
      true
    end.returns(
      {
        data: {
          team: {
            labels: {
              nodes: [ { id: "l-working", name: "working" } ],
            },
          },
        },
      },
    )
    Req.stubs(:call).with do |*args, **kwargs|
      opts = req_opts(args, kwargs)
      next false unless graphql?(opts, "mutation IssueUpdate")

      calls << opts
      true
    end.returns({ data: { issueUpdate: { success: true } } })
    calls
  end
end
