module RspecApiDocumentation
  module Swaggers
    module Helper
      module_function

      def extract_type(value)
        case value
        when Rack::Test::UploadedFile then :file
        when Array then :array
        when Hash then :object
        when TrueClass, FalseClass then :boolean
        when Integer then :integer
        when Float then :number
        else :string
        end
      end

      def extract_items(value)
        result = {type: extract_type(value)}
        result[:items] = extract_items(value[0]) if result[:type] == :array
        result
      end
    end
  end
end
