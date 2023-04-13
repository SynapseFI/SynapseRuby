# frozen_string_literal: true

File.expand_path('lib', __dir__)
require 'minitest/autorun'
require 'minitest/reporters'
require 'synapse_fi'

# load environment variables
require 'dotenv'
Dotenv.load

Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
