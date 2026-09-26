require_relative "test_helper"

class ReqTest < Minitest::Test
  def test_json_request
    stub_request(:post, "https://example.com/items?page=2")
      .with(body: '{"item":"value"}', headers: { "Content-Type" => "application/json" })
      .to_return(body: '{"item_id":3}')

    result = ManagerTestMethods::REQ_CALL.call(
      url: "https://example.com/items",
      method: :post,
      params: { page: 2 },
      payload: { item: "value" },
    )

    assert_equal({ item_id: 3 }, result)
  end

  def test_empty_body
    stub_request(:get, "https://example.com/empty").to_return(body: "")

    result = ManagerTestMethods::REQ_CALL.call(url: "https://example.com/empty")

    assert_equal({}, result)
  end
end
