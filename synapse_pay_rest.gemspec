lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(synapse_api) unless $LOAD_PATH.include?(synapse_api)
require 'date'
require 'synapse_api/version'

Gem::Specification.new do |s|
  s.name     = 'synapse_pay_rest'
  s.version  = SynapsePayRest::VERSION
  s.date     = Date.today.to_s
  s.author  = ['Emmanuel Mawutor']
  s.email    = 'help@synapsepay.com'
  s.summary  = 'SynapsePay v3 Rest Native API Library'
  s.homepage = 'https://rubygems.org/gems/synapse_pay_rest'
  s.license  = 'MIT'

  s.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 2.1.0'

  s.add_dependency 'rest-client', '~> 2.0'

  s.add_development_dependency 'bundler', '~> 1.10'
  s.add_development_dependency 'minitest', '~> 5.8.2'
  s.add_development_dependency 'minitest-reporters', '~> 1.1.5'
  s.add_development_dependency 'dotenv', '~> 2.1.1'
end


# https://stackoverflow.com/questions/25190363/what-are-files-executables-test-files-and-require-paths-in-gemspec-fi
# s.add_development_dependency 'simplecov', '~> 0.12.0'  # counts the number of times each line of application code is run during your test suite
# s.add_development_dependency 'm', '~> 1.5.0' # testing to run test line by line
# s.add_development_dependency 'rake', '~> 10.0' # dont need, i dont have any rake test files


source 'https://rubygems.org'
source 'https://rubygems.org'


gem 'synapse_pay_rest'
