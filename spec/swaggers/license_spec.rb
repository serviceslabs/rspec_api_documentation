require 'spec_helper'

describe RspecApiDocumentation::Swaggers::License do
  let(:node) { RspecApiDocumentation::Swaggers::License.new }
  subject { node }

  describe "default settings" do
    its(:name) { should == 'Apache 2.0' }
    its(:url) { should == 'http://www.apache.org/licenses/LICENSE-2.0.html' }
  end
end
