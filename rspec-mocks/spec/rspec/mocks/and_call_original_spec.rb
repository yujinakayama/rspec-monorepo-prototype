require 'spec_helper'

describe "and_call_original" do
  context "on a partial mock object" do
    let(:klass) do
      Class.new do
        def meth_1
          :original
        end

        def meth_2(x)
          yield x, 3
        end

        def self.new_instance
          new
        end
      end
    end

    let(:instance) { klass.new }

    it 'passes the received message through to the original method' do
      instance.should_receive(:meth_1).and_call_original
      expect(instance.meth_1).to eq(:original)
    end

    it 'passes args and blocks through to the original method' do
      instance.should_receive(:meth_2).and_call_original
      value = instance.meth_2(2) { |a, b| a * b }
      expect(value).to eq(6)
    end

    it 'works for singleton methods' do
      def instance.foo; :bar; end
      instance.should_receive(:foo).and_call_original
      expect(instance.foo).to eq(:bar)
    end

    it 'works for class methods defined on a superclass' do
      subclass = Class.new(klass)
      subclass.should_receive(:new_instance).and_call_original
      expect(subclass.new_instance).to be_a(subclass)
    end

    it 'works for class methods defined on a grandparent class' do
      sub_subclass = Class.new(Class.new(klass))
      sub_subclass.should_receive(:new_instance).and_call_original
      expect(sub_subclass.new_instance).to be_a(sub_subclass)
    end

    it 'works for class methods defined on the Class class' do
      klass.should_receive(:new).and_call_original
      expect(klass.new).to be_an_instance_of(klass)
    end

    it "works for instance methods defined on the object's class's superclass" do
      subclass = Class.new(klass)
      inst = subclass.new
      inst.should_receive(:meth_1).and_call_original
      expect(inst.meth_1).to eq(:original)
    end

    context 'on an object that defines method_missing' do
      before do
        klass.class_eval do
          private

          def method_missing(name, *args)
            return super unless name.to_s =~ /^greet_(.*)$/
            "Hello, #{$1}"
          end
        end
      end

      it 'works when the method_missing definition handles the message' do
        instance.should_receive(:greet_jack).and_call_original
        expect(instance.greet_jack).to eq("Hello, jack")
      end

      it 'raises an error on invocation if method_missing does not handle the message' do
        instance.should_receive(:not_a_handled_message).and_call_original

        # Note: it should raise a NoMethodError (and usually does), but
        # due to a weird rspec-expectations issue (see #183) it sometimes
        # raises a `NameError` when a `be_xxx` predicate matcher has been
        # recently used. `NameError` is the superclass of `NoMethodError`
        # so this example will pass regardless.
        # If/when we solve the rspec-expectations issue, this can (and should)
        # be changed to `NoMethodError`.
        expect {
          instance.not_a_handled_message
        }.to raise_error(NameError, /not_a_handled_message/)
      end
    end
  end

  context "on a partial mock object that overrides #method" do
    let(:request_klass) do
      Struct.new(:method, :url) do
        def perform
          :the_response
        end

        def self.method
          :some_method
        end
      end
    end

    let(:request) { request_klass.new(:get, "http://foo.com/bar") }

    it 'still works even though #method has been overriden' do
      request.should_receive(:perform).and_call_original
      expect(request.perform).to eq(:the_response)
    end

    it 'works for a singleton method' do
      def request.perform
        :a_response
      end

      request.should_receive(:perform).and_call_original
      expect(request.perform).to eq(:a_response)
    end
  end

  context "on a pure mock object" do
    let(:instance) { double }

    it 'raises an error even if the mock object responds to the message' do
      expect(instance.to_s).to be_a(String)
      mock_expectation = instance.should_receive(:to_s)
      instance.to_s # to satisfy the expectation

      expect {
        mock_expectation.and_call_original
      }.to raise_error(/and_call_original.*partial mock/i)
    end
  end
end

