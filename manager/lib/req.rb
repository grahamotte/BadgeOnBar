class Req
  class << self
    def call(url:, method: :get, headers: {}, params: {}, payload: {})
      connection = Faraday.new(
        url:,
        params:,
        headers: { "Content-Type" => "application/json" }.merge(headers),
      ) do |faraday|
        faraday.use Faraday::Response::RaiseError
      end
      response = connection.send(method) do |request|
        request.body = payload.to_json if payload.present?
      end

      JSON.parse(response.body.blank? ? "{}" : response.body, symbolize_names: true)
    end
  end
end
