require 'logstash-logger'
require 'thread'
require 'securerandom'
@logger = LogStashLogger.new(
  type: :tcp,
  host: '0.0.0.0',
  port: 5140,
  buffer_max_items: 5_000,
  buffer_max_interval: 5
)

LogStashLogger.configure do |config|
  config.customize_event do |event|
    event[:trace_id] = Thread.current[:trace_id]
    event[:trace] = Thread.current[:trace]
    event[:service] = Thread.current[:service]
    event[:context] = {
      foo: 'bar'
    }
  end
  config.max_message_size = 40_000
end

Thread.current[:trace_id] = SecureRandom.uuid

def trace(message:, category:, service:)
  begin
    started = Time.now
    yield
    completed = Time.now
    Thread.current[:service] = service
    duration = completed - started
    Thread.current[:trace] = {
      category: category,
      started: started.to_f,
      completed: completed.to_f,
      duration: duration,
      request_duration: duration / 100 * 20,
      queue_duration: duration / 100 * 10,
      process_duration: duration / 100 * 50,
      response_duration: duration / 100 * 20
    }
    require 'pry'
    @logger.info message
  ensure
    Thread.current[:trace] = nil
  end
end

trace(message: 'HTTP Call', category: 'Web', service: 'Host Application') do
  trace(message: 'HTTP Call', category: 'Web', service: 'Service A') do
    sleep 1
  end
  trace(message: 'Call service B', category: 'Web', service: 'Service B') do
    sleep 0.7
  end
end

