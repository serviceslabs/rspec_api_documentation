require 'spec_helper'

describe RspecApiDocumentation::Swaggers::Root do
  let(:node) { RspecApiDocumentation::Swaggers::Root.new }
  subject { node }

  describe "default settings" do
    class RspecApiDocumentation::Swaggers::Info; end
    class RspecApiDocumentation::Swaggers::Paths; end

    its(:swagger) { should == '2.0' }
    its(:info) { should be_a(RspecApiDocumentation::Swaggers::Info) }
    its(:host) { should == 'localhost:3000' }
    its(:basePath) { should be_nil }
    its(:schemes) { should == %w(http https) }
    its(:consumes) { should == %w(application/json application/xml) }
    its(:produces) { should == %w(application/json application/xml) }
    its(:paths) { should be_a(RspecApiDocumentation::Swaggers::Paths) }
    its(:definitions) { should be_nil }
    its(:parameters) { should be_nil }
    its(:responses) { should be_nil }
    its(:securityDefinitions) { should be_nil }
    its(:security) { should be_nil }
    its(:tags) { should == [] }
    its(:externalDocs) { should be_nil }
  end
end
