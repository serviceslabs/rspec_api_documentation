module RspecApiDocumentation
  module Swaggers
    class Info < Node
      add_setting :title, :default => 'Swagger Sample App', :required => true
      add_setting :description, :default => 'This is a sample server Petstore server.'
      add_setting :termsOfService, :default => 'http://swagger.io/terms/'
      add_setting :contact, :default => Contact.new, :schema => Contact
      add_setting :license, :default => License.new, :schema => License
      add_setting :version, :default => '1.0.1', :required => true
    end
  end
end
