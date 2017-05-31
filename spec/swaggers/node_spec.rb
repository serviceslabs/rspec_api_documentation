require 'spec_helper'

describe RspecApiDocumentation::Swaggers::Node do
  let(:node) { RspecApiDocumentation::Swaggers::Node.new }
  its(:settings) { should == {} }

  describe ".add_setting" do
    it "should allow creating a new setting" do
      RspecApiDocumentation::Swaggers::Node.add_setting :new_setting
      expect(node).to respond_to(:new_setting)
      expect(node).to respond_to(:new_setting=)
    end

    it "should allow setting a default" do
      RspecApiDocumentation::Swaggers::Node.add_setting :new_setting, :default => "default"
      expect(node.new_setting).to eq("default")
    end

    it "should allow the default setting to be a lambda" do
      RspecApiDocumentation::Swaggers::Node.add_setting :another_setting, :default => lambda { |config| config.new_setting }
      expect(node.another_setting).to eq("default")
    end

    context "setting can be required" do
      it "should raise error without value and default option" do
        RspecApiDocumentation::Swaggers::Node.add_setting :required_setting, :required => true
        expect { node.required_setting }.to raise_error RuntimeError
      end

      it "should not raise error with default option" do
        RspecApiDocumentation::Swaggers::Node.add_setting :required_setting, :required => true, :default => "value"
        expect(node.required_setting).to eq("value")
      end

      it "should not raise error with value and without default option" do
        RspecApiDocumentation::Swaggers::Node.add_setting :required_setting, :required => true
        node.required_setting = "value"
        expect(node.required_setting).to eq("value")
      end
    end
  end
end
