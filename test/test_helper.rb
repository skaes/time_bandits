require 'test/unit'
require 'mocha/setup'
require 'active_support/testing/declarative'

require 'minitest/pride'

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
end

require_relative '../lib/time_bandits'
