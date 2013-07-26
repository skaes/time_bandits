require 'test/unit'
require 'mocha/setup'
require 'active_support/testing/declarative'

require 'minitest/pride'

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
end

require_relative '../lib/time_bandits'

ActiveSupport::LogSubscriber.class_eval do
  # need a logger, otherwise no data will be collected
  def logger
    @logger ||= Logger.new(STDOUT)
  end
end
