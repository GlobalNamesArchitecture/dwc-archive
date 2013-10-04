require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'dwc-archive'
require 'rspec'
require 'rspec/autorun'

RSpec.configure do |config|

end
