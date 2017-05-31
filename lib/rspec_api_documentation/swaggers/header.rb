module RspecApiDocumentation
  module Swaggers
    class Header < Node
      add_setting :description
      add_setting :type, :required => true, :default => lambda { |header|
        case header.public_send('x-example-value')
        when Integer then 'integer'
        when Float then 'number'
        when TrueClass, FalseClass then 'boolean'
        when Array then 'array'
        else 'string'
        end
      }
      add_setting :format
      add_setting 'x-example-value'
    end
  end
end
