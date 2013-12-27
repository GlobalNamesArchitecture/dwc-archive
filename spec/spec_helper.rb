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

unless defined?(SPEC_CONSTANTS)
  EML_DATA = {
      id: '1234',
      license: 'http://creativecommons.org/licenses/by-sa/3.0/',
      title: 'Test Classification',
      authors: [
        { first_name: 'John',
          last_name: 'Doe',
          email: 'jdoe@example.com',
          organization: 'Example',
          position: 'Assistant Professor',
          url: 'http://example.org' },
          { first_name: 'Jane',
            last_name: 'Doe',
            email: 'jane@example.com' }
    ],
      metadata_providers: [
        { first_name: 'Jim',
          last_name: 'Doe',
          email: 'jimdoe@example.com',
          url: 'http://aggregator.example.org' }],
      abstract: 'test classification',
      citation:
        'Test classification: Doe John, Doe Jane, Taxnonmy, 10, 1, 2010',
      url: 'http://example.com'
    }
  SPEC_CONSTANTS = true
end
