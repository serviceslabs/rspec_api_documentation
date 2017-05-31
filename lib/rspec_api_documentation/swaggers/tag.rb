module RspecApiDocumentation
  module Swaggers
    class Tag < Node
      add_setting :name, :required => true
      add_setting :description
      add_setting :externalDocs
    end
  end
end
