module RspecApiDocumentation
  module Swaggers
    class Parameter < Node
      add_setting :name, :required => true
      add_setting :in, :required => true
      add_setting :description
      add_setting :required, :default => lambda { |parameter| parameter.in.to_s == 'path' ? true : false }
      add_setting :schema
      add_setting :type
      add_setting :format
    end
  end
end
