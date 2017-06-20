require 'rspec_api_documentation/writers/formatter'
require 'yaml'

module RspecApiDocumentation
  module Writers
    class SwaggerWriter < Writer
      FILENAME = 'swagger'

      delegate :docs_dir, :swagger_config_path, to: :configuration

      def write
        File.open(docs_dir.join("#{FILENAME}.json"), 'w+') do |f|
          f.write Formatter.to_json(SwaggerIndex.new(index, configuration, load_config))
        end
      end

      def load_config
        YAML.load_file(swagger_config_path) if File.exist?(swagger_config_path)
      end
    end

    class SwaggerIndex
      attr_reader :index, :configuration, :init_config

      def initialize(index, configuration, init_config)
        @index = index
        @configuration = configuration
        @init_config = init_config
      end

      def as_json
        swagger = init_config ? Swaggers::Root.new(init_config) : Swaggers::Root.new
        swagger.tags = extract_tags
        swagger.paths = extract_paths
        swagger.securityDefinitions = extract_security_definitions
        swagger.as_json
      end

      private

      def examples
        index.examples.map { |example| SwaggerExample.new(example) }
      end

      def extract_security_definitions
        security_definitions = Swaggers::SecurityDefinitions.new

        arr = examples.map do |example|
          example.respond_to?(:authentications) ? example.authentications : nil
        end.compact

        arr.each do |securities|
          securities.each do |security, opts|
            schema = Swaggers::SecuritySchema.new(
              name: opts[:name],
              description: opts[:description],
              type: opts[:type],
              in: opts[:in]
            )
            security_definitions.add_setting security, :value => schema
          end
        end
        security_definitions unless arr.empty?
      end

      def extract_tags
        tags = {}
        examples.each do |example|
          tags[example.resource_name] = tags[example.resource_name] || example.resource_explanation
        end
        tags.map { |(k, v)| Swaggers::Tag.new(name: k, description: v) }
      end

      def extract_paths
        paths = Swaggers::Paths.new
        examples.each do |example|
          paths.add_setting example.route, :value => Swaggers::Path.new

          operation = paths.setting(example.route).setting(example.http_method) || Swaggers::Operation.new(
            tags: [example.resource_name],
            summary: example.description,
            description: example.explanation || '',
            responses: Swaggers::Responses.new,
            parameters: extract_parameters(example),
            consumes: example.requests.map { |request| request[:request_content_type] }.compact.map { |q| q[/[^;]+/] },
            produces: example.requests.map { |request| request[:response_content_type] }.compact.map { |q| q[/[^;]+/] },
            security: example.respond_to?(:authentications) ? example.authentications.map { |(k, _)| {k => []} } : []
          )

          add_responses(operation.responses, example)

          paths.setting(example.route).assign_setting(example.http_method, operation)
        end
        paths
      end

      def add_responses(responses, example)
        schema = extract_schema(example.respond_to?(:response_fields) ? example.response_fields : [])
        example.requests.each do |request|
          response = Swaggers::Response.new(
            description: request[:response_status_text],
            schema: schema
          )

          if request[:response_headers]
            response.headers ||= Swaggers::Headers.new
            request[:response_headers].each do |header, value|
              response.headers.add_setting header, :value => Swaggers::Header.new('x-example-value' => value)
            end
          end

          if /\A(?<response_content_type>[^;]+)/ =~ request[:response_content_type]
            response.examples ||= Swaggers::Example.new
            response_body = JSON.parse(request[:response_body]) rescue nil
            response.examples.add_setting response_content_type, :value => response_body
          end
          responses.add_setting "#{request[:response_status]}", :value => response
        end
        responses
      end

      def extract_schema(fields)
        schema = {type: 'object', properties: {}}

        fields.each do |field|
          current = schema
          if field[:scope]
            [*field[:scope]].each do |scope|
              current[:properties][scope] ||= {type: 'object', properties: {}}
              current = current[:properties][scope]
            end
          end
          current[:properties][field[:name]] = {type: field[:type] || swagger_type(field[:value])}
          current[:required] ||= [] << field[:name] if field[:required]
        end

        Swaggers::Schema.new(schema)
      end

      def extract_parameters(example)
        known = extract_known_parameters(example.extended_parameters.select { |p| !p[:in].nil? })
        unknown = extract_unknown_parameters(example, example.extended_parameters.select { |p| p[:in].nil? })
        known + unknown
      end

      def extract_unknown_parameters(example, parameters)
        result = []

        if example.http_method == :get
          parameters.each do |parameter|
            result << Swaggers::Parameter.new(
              name: parameter[:name],
              in: :query,
              description: parameter[:description],
              required: parameter[:required],
              type: parameter[:type] || swagger_type(parameter[:value])
            )
          end
        elsif parameters.any? { |parameter| !parameter[:scope].nil? }
          result.unshift(
            Swaggers::Parameter.new(
              name: :body,
              in: :body,
              description: '',
              schema: extract_schema(parameters)
            )
          )
        else
          parameters.each do |parameter|
            result << Swaggers::Parameter.new(
              name: parameter[:name],
              in: :formData,
              description: parameter[:description],
              required: parameter[:required],
              type: parameter[:type] || swagger_type(parameter[:value])
            )
          end
        end

        result
      end

      def extract_known_parameters(parameters)
        result = []

        parameters.select { |parameter| %w(query path header formData).include?(parameter[:in].to_s) }.each do |parameter|
          result << Swaggers::Parameter.new(
            name: parameter[:name],
            in: parameter[:in],
            description: parameter[:description],
            required: parameter[:required],
            type: parameter[:type] || swagger_type(parameter[:value])
          )
        end

        body = parameters.select { |parameter| %w(body).include?(parameter[:in].to_s) }

        result.unshift(
          Swaggers::Parameter.new(
            name: :body,
            in: :body,
            description: '',
            schema: extract_schema(body)
          )
        ) unless body.empty?

        result
      end

      def swagger_type(value)
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

    class SwaggerExample
      def initialize(example)
        @example = example
      end

      def method_missing(method, *args, &block)
        @example.send(method, *args, &block)
      end

      def respond_to?(method, include_private = false)
        super || @example.respond_to?(method, include_private)
      end

      def http_method
        metadata[:method]
      end

      def requests
        super.select { |request| request[:request_method].to_s.downcase == http_method.to_s.downcase }
      end

      def route
        super.gsub(/:(?<parameter>[^\/]+)/, '{\k<parameter>}')
      end
    end
  end
end