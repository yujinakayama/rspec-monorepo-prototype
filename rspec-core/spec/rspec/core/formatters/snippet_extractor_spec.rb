require 'spec_helper'
require 'rspec/core/formatters/snippet_extractor'

module RSpec
  module Core
    module Formatters
      describe SnippetExtractor do
        it "should fall back on a default message when it doesn't understand a line" do
          SnippetExtractor.new.snippet_for("blech").should == ["# Couldn't get snippet for blech", 1]
        end

        it "should fall back on a default message when it doesn't find the file" do
          SnippetExtractor.new.lines_around("blech", 8).should == "# Couldn't get snippet for blech"
        end
      end
    end
  end
end
