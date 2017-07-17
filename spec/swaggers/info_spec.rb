require 'spec_helper'

describe RspecApiDocumentation::Swaggers::Info do
  let(:node) { RspecApiDocumentation::Swaggers::Info.new }
  subject { node }

  describe "default settings" do
    class RspecApiDocumentation::Swaggers::Contact; end
    class RspecApiDocumentation::Swaggers::License; end

    its(:title) { should == 'Swagger Sample App' }
    its(:description) { should == 'This is a sample server Petstore server.' }
    its(:termsOfService) { should == 'http://swagger.io/terms/' }
    its(:contact) { should be_a(RspecApiDocumentation::Swaggers::Contact) }
    its(:license) { should be_a(RspecApiDocumentation::Swaggers::License) }
    its(:version) { should == '1.0.1' }
  end
end
