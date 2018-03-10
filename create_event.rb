require 'logstash-logger'
require 'thread'
require 'securerandom'
logger = LogStashLogger.new(type: :tcp, host: '0.0.0.0', port: 5140)

LogStashLogger.configure do |config|
  config.customize_event do |event|
    event['request_id'] = Thread.current[:request_id]
  end
  config.max_message_size = 40_000
end

Thread.current[:request_id] = SecureRandom.uuid
logger.info 'hello world'
