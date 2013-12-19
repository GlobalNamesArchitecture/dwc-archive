# HACK: to suppress warnings
$VERBOSE = nil

require 'coveralls'
Coveralls.wear!

require 'dwc-archive'
require 'rspec'
require 'rspec/mocks'
require 'socket'

RSpec.configure do |config|
end

