module RSpec
  describe Expectations do
    def file_contents_for(lib, filename)
      # http://rubular.com/r/HYpUMftlG2
      path = $LOAD_PATH.find { |p| p.match(/\/rspec-#{lib}(-[a-f0-9]+)?\/lib/) }
      file = File.join(path, filename)
      File.read(file)
    end

    it 'has an up-to-date caller_filter file' do
      expectations = file_contents_for("expectations", "rspec/expectations/caller_filter.rb")
      core         = file_contents_for("core",         "rspec/core/caller_filter.rb")

      expect(expectations).to eq(core)
    end
  end
end

