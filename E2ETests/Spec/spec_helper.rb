require 'serverspec'
require 'rspec/teamcity'
require 'octopus_serverspec_extensions'

set :backend, :cmd
set :os, :family => 'windows'

RSpec.configure do |c|
  if (ENV['TEAMCITY_PROJECT_NAME']) then
    c.add_formatter Spec::Runner::Formatter::TeamcityFormatter
  end
end
