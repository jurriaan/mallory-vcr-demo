require 'vcr'
require 'cucumber/rspec/doubles'
require 'logging'
require 'mallory'


def get_logger(activity_log, request_log, verbose)
  # https://github.com/TwP/logging/blob/master/lib/logging/layouts/pattern.rb
  Logging.init :request, :debug, :info
  layout = Logging::Layouts::Pattern.new(pattern: "%d %-5l : %m\n")
  logger = Logging.logger['mallory']

  activity_appender = Logging.appenders.stdout
  activity_appender = Logging.appenders.file(activity_log) unless activity_log.nil?
  activity_appender.layout = layout
  activity_appender.level = verbose ? :debug : :info
  logger.add_appenders(activity_appender)

  unless request_log.nil?
    request_appender = Logging.appenders.file(request_log)
    request_appender.layout = layout
    request_appender.level = :request
    logger.add_appenders(request_appender)
  end

  logger
end

config = Mallory::Configuration.register do |c|
  c.logger = get_logger(nil, nil, nil)
  ca = Mallory::SSL::CA.new('./keys/ca.crt', './keys/ca.key')
  cf = Mallory::SSL::CertificateFactory.new(ca)
  st = Mallory::SSL::MemoryStorage.new
  c.certificate_manager = Mallory::SSL::CertificateManager.new(cf, st)
  c.connect_timeout = 10
  c.inactivity_timeout = 10
  c.port = 9999
end

Thread.new { Mallory::Server.new(config).start! }
sleep 0.1 until EventMachine.reactor_running?

puts "Waiting till proxy server is booted" # TODO: use some flag to determine this instead of sleeping
sleep 2

VCR.configure do |c|
  c.cassette_library_dir = "features/fixtures/cassettes"
  c.hook_into :webmock # Webmock hooks in into the internal proxy server
  c.default_cassette_options = { match_requests_on: %i(method host path), decode_compressed_response: true, record: (ENV['CI'] ? :none : :new_episodes), allow_unused_http_interactions: false }
  c.allow_http_connections_when_no_cassette = false
end

VCR.cucumber_tags do |t|
  t.tag '@vcr', use_scenario_name: true
end
