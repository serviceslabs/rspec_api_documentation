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
    end
  end
end
