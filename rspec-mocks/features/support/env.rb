require 'bundler'
Bundler.setup

require 'aruba'
require 'rspec/expectations'

module ArubaOverrides
  def detect_ruby_script(cmd)
    if cmd =~ /^rspec /
      "bundle exec ../../../rspec-core/bin/#{cmd}"
    elsif cmd =~ /^ruby /
      "bundle exec #{cmd}"
    else
      super(cmd)
    end
  end
end

World(ArubaOverrides)


