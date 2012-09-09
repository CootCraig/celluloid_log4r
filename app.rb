require "rubygems"
require "bundler/setup"

require 'log4r/yamlconfigurator'
require 'celluloid'
require 'log4r'


class EventSource
  include Celluloid
  def initialize
    @event_count = 0
    async.run
  end
  def run
    loop do
      sleep 3
      @event_count += 1
      App::logger.debug "EventSource.run calling :event_handler #{@event_count}"
      Celluloid::Actor[:event_handler].async.event @event_count
    end
  end
end
class EventHandler
  include Celluloid
  include Celluloid::Logger

  def event count
    info "EventHandler.event: count #{count}"
  end
end
class App
  @@logger = nil
  VERSION = '0.0.2'

  def self.setup
    @@app_config_file = File.expand_path('app.yml')
    puts "log4r config file is #{@@app_config_file}"
    Log4r::YamlConfigurator.load_yaml_file @@app_config_file
    @@logger = Log4r::Logger['base']
    Celluloid.logger = @@logger
    logger.debug "App::setup version #{App::VERSION}"
  end
  def self.run
    EventHandler.supervise_as :event_handler
    EventSource.supervise_as :event_source
    sleep
  end
  def self.logger
    @@logger
  end
end

App.setup
App.run

