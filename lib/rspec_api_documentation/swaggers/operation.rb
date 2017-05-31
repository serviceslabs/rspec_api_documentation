module RspecApiDocumentation
  module Swaggers
    class Operation < Node
      add_setting :tags, :default => []
      add_setting :summary
      add_setting :description
      add_setting :externalDocs
      add_setting :operationId
      add_setting :consumes
      add_setting :produces
      add_setting :parameters, :default => []
      add_setting :responses, :required => true
      add_setting :schemes
      add_setting :deprecated, :default => false
      add_setting :security
    end
  end
end
