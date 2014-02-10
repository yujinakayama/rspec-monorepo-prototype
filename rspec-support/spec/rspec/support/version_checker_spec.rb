require 'spec_helper'
require 'rspec/support/version_checker'

module RSpec::Support
  describe VersionChecker do
    def check_version(*args)
      VersionChecker.new(*args).check_version!
    end

    it 'raises an error if the major version is too low' do
      expect { check_version('some_gem', '0.7.3', '1.0.0') }.to raise_error(LibraryVersionTooLowError)
    end

    it 'raises an error if the minor version is too low' do
      expect { check_version('some_gem', '1.0.99', '1.1.3') }.to raise_error(LibraryVersionTooLowError)
    end

    it 'raises an error if the patch version is too low' do
      expect { check_version('some_gem', '1.0.8', '1.0.10') }.to raise_error(LibraryVersionTooLowError)
    end

    it 'does not raise an error or print a warning when the version is above the min version' do
      expect(Kernel).not_to receive(:warn)
      check_version('some_gem', '2.0.0', '1.0.0')
    end
  end
end
