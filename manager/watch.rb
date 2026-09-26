require_relative "lib/require"

begin
  Sync.call
rescue Faraday::Error => error
  puts error.full_message
end

loop do
  Watch.call
  sleep 60
end
