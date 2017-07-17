require 'spec_helper'

describe RspecApiDocumentation::Swaggers::Contact do
  let(:node) { RspecApiDocumentation::Swaggers::Contact.new }
  subject { node }

  describe "default settings" do
    its(:name) { should == 'API Support' }
    its(:url) { should == 'http://www.swagger.io/support' }
    its(:email) { should == 'support@swagger.io' }
  end
end
