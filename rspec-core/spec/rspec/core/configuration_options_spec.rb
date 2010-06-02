require 'spec_helper'

require 'ostruct'

describe RSpec::Core::ConfigurationOptions do
  
  def config_options_object(*args)
    RSpec::Core::ConfigurationOptions.new(args)
  end

  def options_from_args(*args)
    config_options_object(*args).options
  end

  describe 'color_enabled' do
    example "-c, --colour, or --color are parsed as true" do
      options_from_args('-c').should include(:color_enabled => true)
      options_from_args('--color').should include(:color_enabled => true)
      options_from_args('--colour').should include(:color_enabled => true)
    end

    example "--no-color is parsed as false" do
      options_from_args('--no-color').should include(:color_enabled => false)
    end
  end

  describe 'load path additions' do
    example "-I parses like it does w/ ruby command" do
      options_from_args('-I', 'a_dir').should include(:libs => ['a_dir'])
    end
    example "-I can be used more than once" do
      options_from_args('-I', 'dir_1', '-I', 'dir_2').should include(:libs => ['dir_1','dir_2'])
    end
  end

  describe  'formatter' do
    example '-f or --formatter with an argument should parse' do
      options_from_args('--formatter', 'd').should include(:formatter => 'd')
      options_from_args('-f', 'd').should include(:formatter => 'd')
      options_from_args('-fd').should include(:formatter => 'd')
    end
  end

  describe 'profile_examples' do
    example "-p or --profile should be parsed as true" do
      options_from_args('-p').should include(:profile_examples => true)
      options_from_args('--profile').should include(:profile_examples => true)
    end
  end

  describe 'line_number' do
    it "is parsed from -l or --line_number" do
      options_from_args('-l','3').should include(:line_number => '3')
      options_from_args('--line_number','3').should include(:line_number => '3')
    end
  end

  describe "example" do
    it "is parsed from --example or -e" do
      options_from_args('--example','foo').should include(:full_description => /foo/)
      options_from_args('-e','bar').should include(:full_description => /bar/)
    end
  end

  describe "options file" do
    it "is parsed from --options or -o" do
      options_from_args("--options", "custom/path").should include(:options_file => "custom/path")
      options_from_args("-o", "custom/path").should include(:options_file => "custom/path")
    end
  end

  describe "files_or_directories_to_run" do
    it "parses files from '-c file.rb dir/file.rb'" do
      options_from_args("-c", "file.rb", "dir/file.rb").should include(:files_or_directories_to_run => ["file.rb", "dir/file.rb"])
    end

    it "parses dir from 'dir'" do
      options_from_args("dir").should include(:files_or_directories_to_run => ["dir"])
    end

    it "parses dir and files from 'spec/file1_spec.rb, spec/file2_spec.rb'" do
      options_from_args("dir", "spec/file1_spec.rb", "spec/file2_spec.rb").should include(:files_or_directories_to_run => ["dir", "spec/file1_spec.rb", "spec/file2_spec.rb"])
    end

    it "provides no files or directories if spec directory does not exist" do
      FileTest.stub(:directory?).with("spec").and_return false
      options_from_args().should include(:files_or_directories_to_run => [])
    end

    it "parses dir and files from 'spec/file1_spec.rb, spec/file2_spec.rb'" do
      options_from_args("dir", "spec/file1_spec.rb", "spec/file2_spec.rb").should include(:files_or_directories_to_run => ["dir", "spec/file1_spec.rb", "spec/file2_spec.rb"])
      
    end

  end

  describe "--backtrace (-b)" do
    it "sets full_backtrace on config" do
      options_from_args("--backtrace").should include(:full_backtrace => true)
      options_from_args("-b").should include(:full_backtrace => true)
    end
  end

  describe "--debug (-d)" do
    it "sets debug on config" do
      options_from_args("--debug").should include(:debug => true)
      options_from_args("-d").should include(:debug => true)
    end
  end
  
  describe "--drb (-X)" do
    context "combined with --debug" do
      it "turns off the debugger if --drb is specified first" do
        config_options_object("--drb", "--debug").drb_argv.should_not include("--debug")
        config_options_object("--drb", "-d"     ).drb_argv.should_not include("--debug")
        config_options_object("-X",    "--debug").drb_argv.should_not include("--debug")
        config_options_object("-X",    "-d"     ).drb_argv.should_not include("--debug")
      end
      
      it "turns off the debugger option if --drb is specified later" do      
        config_options_object("--debug", "--drb").drb_argv.should_not include("--debug")
        config_options_object("-d",      "--drb").drb_argv.should_not include("--debug")
        config_options_object("--debug", "-X"   ).drb_argv.should_not include("--debug")
        config_options_object("-d",      "-X"   ).drb_argv.should_not include("--debug")
      end
      
      it "turns off the debugger option if --drb is specified in the options file" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb  ] }
        config_options_object("--debug").drb_argv.should_not include("--debug")
        config_options_object("-d"     ).drb_argv.should_not include("--debug")        
      end
      
      it "turns off the debugger option if --debug is specified in the options file" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --debug  ] }
        config_options_object("--drb").drb_argv.should_not include("--debug")
        config_options_object("-X"   ).drb_argv.should_not include("--debug")        
      end
    end
        
    it "sends all the arguments other than --drb back to the parser after parsing options" do
      config_options_object("--drb", "--color").drb_argv.should_not include("--drb")
    end
  end
  
  
  # TODO #drb_argv may not be the best name
  # TODO ensure all options are output
  # TODO check if we need to spec that the short options are "expanded" ("-v" becomes "--version" currently)
  describe "#drb_argv" do
    it "preserves extra arguments" do
      config_options_object(*%w[ a --drb b --color c ]).drb_argv.should eq(%w[ --color a b c ])
    end
    
    context "--drb specified in ARGV" do
      it "renders all the original arguments except --drb" do
        config_options_object(*%w[ --drb --color --formatter s --line_number 1 --example pattern --profile --backtrace]).
          drb_argv.should eq(%w[ --color --profile --backtrace --formatter s --line_number 1 --example pattern ])
      end
    end

    context "--drb specified in the options file" do
      it "renders all the original arguments except --drb" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb --color ] }
        config_options_object(*%w[ --formatter s --line_number 1 --example pattern --profile --backtrace ]).
          drb_argv.should eq(%w[ --color --profile --backtrace --formatter s --line_number 1 --example pattern ])
      end
    end

    context "--drb specified in ARGV and the options file" do
      it "renders all the original arguments except --drb" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb --color ] }
        config_options_object(*%w[ --drb --formatter s --line_number 1 --example pattern --profile --backtrace]).
          drb_argv.should eq(%w[ --color --profile --backtrace --formatter s --line_number 1 --example pattern ])
      end
    end

    context "--drb specified in ARGV and in as ARGV-specified --options file" do
      it "renders all the original arguments except --drb and --options" do
        File.stub(:exist?) { true }
        File.stub(:readlines) { %w[ --drb --color ] }
        config_options_object(*%w[ --drb --formatter s --line_number 1 --example pattern --profile --backtrace]).
          drb_argv.should eq(%w[ --color --profile --backtrace --formatter s --line_number 1 --example pattern ])
      end
    end
  end

  describe "options file (override)" do
    let(:config) { OpenStruct.new }

    it "loads automatically" do
      File.stub(:exist?) { true }
      File.stub(:readlines) { ["--formatter", "doc"] }

      cli_options = RSpec::Core::ConfigurationOptions.new([])
      cli_options.configure(config)
      config.formatter.should == 'doc'
    end
    
    it "allows options on one line" do
      File.stub(:exist?) { true }
      File.stub(:readlines) { ["--formatter doc"] }

      cli_options = RSpec::Core::ConfigurationOptions.new([])
      cli_options.configure(config)
      config.formatter.should == 'doc'
    end
    
    it "merges options from the global and local .rspec and the command line" do
      File.stub(:exist?){ true }
      File.stub(:readlines) do |path|
        case path
        when ".rspec"
          ["--formatter", "documentation"] 
        when /\.rspec/
          ["--line", "37"]
        else
          raise "Unexpected path: #{path}"
        end
      end
      cli_options = RSpec::Core::ConfigurationOptions.new(["--no-color"])

      cli_options.configure(config)

      config.formatter.should == "documentation"
      config.line_number.should == "37"
      config.color_enabled.should be_false
    end
    
    it "prefers local options over global" do
      File.stub(:exist?){ true }
      File.stub(:readlines) do |path|
        case path
        when ".rspec"
          ["--formatter", "local"] 
        when /\.rspec/
          ["--formatter", "global"] 
        else
          raise "Unexpected path: #{path}"
        end
      end
      cli_options = RSpec::Core::ConfigurationOptions.new([])

      cli_options.configure(config)

      config.formatter.should == "local"
    end

    it "prefers CLI options over file options" do
      config_options = RSpec::Core::ConfigurationOptions.new(['--formatter', 'progress'])
      config_options.stub(:parse_options_file).and_return(:formatter => 'documentation')

      config_options.configure(config)

      config.formatter.should == 'progress'
    end
  end
end

