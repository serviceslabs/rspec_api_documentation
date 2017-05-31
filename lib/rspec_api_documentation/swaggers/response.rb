module RspecApiDocumentation
  module Swaggers
    class Response < Node
      add_setting :description, :required => true, :default => 'Successful operation'
      add_setting :schema
      add_setting :headers
      add_setting :examples
    end
  end
end
