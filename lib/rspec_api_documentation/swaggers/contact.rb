module RspecApiDocumentation
  module Swaggers
    class Contact < Node
      add_setting :name, :default => 'API Support'
      add_setting :url, :default => 'http://www.swagger.io/support'
      add_setting :email, :default => 'support@swagger.io'
    end
  end
end
