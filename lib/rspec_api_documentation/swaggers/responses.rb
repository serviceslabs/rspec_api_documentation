module RspecApiDocumentation
  module Swaggers
    class Responses < Node
      add_setting :default, :default => lambda { |responses| responses.existing_settings.size > 1 ? nil : Response.new }

      def initialize(opts = {}, from_opts = Response); super end
    end
  end
end
