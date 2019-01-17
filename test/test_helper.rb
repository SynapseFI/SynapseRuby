File.expand_path('../lib', __FILE__)
require 'minitest/autorun'
require 'minitest/reporters'
require 'synapse_fi'

# load environment variables
require'dotenv'
Dotenv.load

Minitest::Reporters.use!([Minitest::Reporters::SpecReporter.new])
