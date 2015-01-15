# encoding: utf-8
require 'spec_helper'
require 'rspec/support/encoded_string'

module RSpec::Support
  describe EncodedString do
    let(:utf8_encoding) { 'UTF-8' }

    delegated_methods = String.instance_methods.map(&:to_s) & %w[eql? lines == encoding empty?]
    delegated_methods.each do |delegated_method|
      it "responds to #{delegated_method}" do
        encoded_string = EncodedString.new("abc", utf8_encoding)
        expect(encoded_string).to respond_to(delegated_method)
      end
    end

    if String.method_defined?(:encoding)

      describe '#source_encoding' do
        it 'knows the original encoding of the string' do
          str = EncodedString.new("abc".encode('ASCII-8BIT'), "UTF-8")
          expect(str.source_encoding.to_s).to eq('ASCII-8BIT')
        end
      end

      describe '#to_s' do
        context 'when encoding a string with invalid bytes in the target encoding' do
          # see https://github.com/jruby/jruby/blob/c1be61a501/test/mri/ruby/test_transcode.rb#L13
          let(:source_encoding) { Encoding.find('US-ASCII') }
          let(:target_encoding) { Encoding.find('UTF-8') }
          let(:string) { "I have a bad byté\x80".force_encoding(source_encoding) }

          it 'normally raises an EncodedString::InvalidByteSequenceError' do
            expect {
              string.encode(target_encoding)
            }.to raise_error(Encoding::InvalidByteSequenceError)
          end

          it 'replaces invalid byte sequences with the REPLACE string' do
            resulting_string = build_encoded_string(string, target_encoding).to_s
            replacement = EncodedString::REPLACE * 3
            expected_string = "I have a bad byt#{replacement}"
            expect(resulting_string).to be_identical_string(expected_string)
          end
        end

        context 'when no converter is known for an encoding' do
          # see https://github.com/rubyspec/rubyspec/blob/91ce9f6549/core/string/shared/encode.rb#L12
          let(:source_encoding) { Encoding.find('ASCII-8BIT') }
          let(:no_converter_encoding) { Encoding::Emacs_Mule }
          let(:string) { "\x80".force_encoding(source_encoding) }

          it 'normally raises an Encoding::ConverterNotFoundError' do
            expect {
              string.encode(no_converter_encoding)
            }.to raise_error(Encoding::ConverterNotFoundError)
          end

          if RUBY_VERSION < '2.1'
            it 'does nothing' do
              resulting_string = build_encoded_string(string, no_converter_encoding).to_s
              expected_string  = "\x80"
              expect(resulting_string).to be_identical_string(expected_string, no_converter_encoding)
            end
          else
            it 'forces the encoding and replaces invalid characters with the REPLACE string' do
              resulting_string = build_encoded_string(string, no_converter_encoding).to_s
              expected_string  = EncodedString::REPLACE
              expect(resulting_string).to be_identical_string(expected_string, no_converter_encoding)
            end
          end
        end

        # see https://github.com/ruby/ruby/blob/34fbf57aaa/transcode.c#L4289
        # ISO-8859-1 -> UTF-8 -> EUC-JP
        # "\xa0" NO-BREAK SPACE, which is available in UTF-8 but not in EUC-JP
        context 'when there is an undefined conversion to the target encoding' do
          let(:source_encoding) { Encoding.find('ISO-8859-1') }
          let(:incompatible_encoding) { Encoding.find('EUC-JP') }
          let(:string) { "\xa0 hi I am not going to work".force_encoding(source_encoding) }

          it 'normally raises an Encoding::UndefinedConversionError' do
            expect {
              string.encode(incompatible_encoding)
            }.to raise_error(Encoding::UndefinedConversionError)
          end

          it 'replaces all undefines conversions with the REPLACE string' do
            resulting_string = build_encoded_string(string, incompatible_encoding).to_s
            replacement = EncodedString::REPLACE
            expected_string = "#{replacement} hi I am not going to work"
            expect(resulting_string).to be_identical_string(expected_string)
          end
        end
      end

      let(:ascii_arrow_symbol) { "\xAE" }
      let(:utf_8_euro_symbol) { "\xE2\x82\xAC" }

      describe '#<<' do
        context 'with strings that can be converted to the target encoding' do
          let(:valid_ascii_string) { "abcdé".force_encoding("ASCII-8BIT") }
          let(:valid_unicode_string) { utf_8_euro_symbol.force_encoding('UTF-8') }
          it 'encodes and appends the string' do

            resulting_string = build_encoded_string(valid_unicode_string, utf8_encoding) << valid_ascii_string
            replacement = EncodedString::REPLACE * 2
            expected_string = "#{utf_8_euro_symbol}abcd#{replacement}".force_encoding('UTF-8')
            expect(resulting_string).to be_identical_string(expected_string)
          end

          it 'copes with encoded strings' do
            source_encoding = Encoding.find('UTF-16LE')
            accentless = build_encoded_string("Tu avec carte {count} item has\n", source_encoding)
            accented   = "Tu avec carté {count} itém has\n".encode(source_encoding)
            resulting_string = accentless << accented
            if OS.windows?
              replacement = "\x82\x82"
            else
              replacement = "\u00E9"
            end
            expected_string = <<-EOS.encode('UTF-16LE')
Tu avec carte {count} item has
Tu avec cart#{replacement} {count} it#{replacement}m has
            EOS
            expect(resulting_string).to be_identical_string(expected_string)
          end
        end

        context 'with a string that cannot be converted to the target encoding' do
          context 'when appending a string with an incompatible character encoding' do
            let(:ascii_string) { ascii_arrow_symbol.force_encoding("ASCII-8BIT") }
            let(:valid_unicode_string) { utf_8_euro_symbol.force_encoding('UTF-8') }

            it "normally raises an Encoding::CompatibilityError" do
              expect {
                valid_unicode_string.encode(utf8_encoding) << ascii_string
              }.to raise_error(Encoding::CompatibilityError)
            end

            it 'replaces unconvertable characters with a string representation of their hex value' do
              resulting_string = build_encoded_string(valid_unicode_string, utf8_encoding) << ascii_string
              expected_string = "#{utf_8_euro_symbol}?"
              expect(resulting_string).to be_identical_string(expected_string)
            end
          end
        end

        context 'with two ascii strings with a target encoding of UTF-8 ' do
          it 'has an encoding of UTF-8' do
            ascii_string = 'abc'.force_encoding("ASCII-8BIT")
            other_ascii_string = '123'.force_encoding("ASCII-8BIT")

            resulting_string = build_encoded_string(ascii_string, utf8_encoding) << other_ascii_string
            expected_string = 'abc123'.force_encoding('ASCII-8BIT')
            expect(resulting_string).to be_identical_string(expected_string)
          end
        end
      end

      describe '#split' do
        context 'when the string has an invalid byte sequence' do
          let(:message_with_invalid_byte_sequence) { "\xEF \255 \xAD I have bad bytes".force_encoding(utf8_encoding) }

          it 'normally raises an ArgumentError' do
            expect {
              message_with_invalid_byte_sequence.split("\n")
            }.to raise_error(ArgumentError)
          end

          it 'replaces invalid bytes with the REPLACE string' do
            skip 'test is raising an ArgumentError on split'
            resulting_array = build_encoded_string(message_with_invalid_byte_sequence, utf8_encoding).split("\n")
            expect(resulting_array.size).to eq(1) # sanity check
            expected_string = "? ? ? I have bad bytes"
            expect_identical_string(resulting_array.first, expected_string)
          end

        end

        context 'when there is an undefined conversion to the target encoding' do
          let(:wrapped_string) { "aaaaaaaaaaa#{ascii_arrow_symbol}aaaaa".force_encoding("ASCII-8BIT") }

          it 'normally raises an Encoding::UndefinedConversionError' do
            expect {
              wrapped_string.encode(utf8_encoding)
            }.to raise_error(Encoding::UndefinedConversionError)
          end

          it 'splits the string based on the delimiter accounting for encoding' do
            expect {
              build_encoded_string(wrapped_string, utf8_encoding).split(utf_8_euro_symbol.force_encoding("UTF-8"))
            }.not_to raise_error
          end
        end

        # see https://github.com/rspec/rspec-expectations/blob/f8a1232/spec/rspec/expectations/fail_with_spec.rb#L50
        #     https://github.com/rspec/rspec-expectations/issues/201
        #     https://github.com/rspec/rspec-expectations/pull/220
        context 'with a string that cannot be converted to the target encoding' do
          let(:binary_poop) {'💩' } # [128169] "\u{1F4A9}"
          let(:non_ascii_compatible_string) { "This is a pile of poo: #{binary_poop}, yuck".encode("UTF-16LE") }

          it 'normally raises an Encoding::CompatibilityError' do
            expect {
              non_ascii_compatible_string.split("\n")
            }.to raise_error(Encoding::CompatibilityError)
          end

          it 'makes no changes to the resulting string' do
            resulting_array = build_encoded_string(non_ascii_compatible_string).split("\n")
            expect(resulting_array.size).to eq(1) # sanity check
            expected_string = non_ascii_compatible_string
            expect_identical_string(resulting_array.first, expected_string, Encoding.find('UTF-16LE'))
          end
        end
      end

      def build_encoded_string(string, target_encoding = string.encoding)
        EncodedString.new(string, target_encoding)
      end
    else

      describe '#source_encoding' do
        it 'defaults to US-ASCII' do
          str = EncodedString.new("abc", "UTF-8")
          expect(str.source_encoding).to eq('US-ASCII')
        end
      end
    end
  end
end
