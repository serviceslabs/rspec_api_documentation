module RspecApiDocumentation
  module Swaggers
    class Node
      def self.add_setting(name, opts = {})
        class_settings << name

        define_method("#{name}_schema") { opts[:schema] || NilClass }
        define_method("#{name}=") { |value| settings[name] = value }
        define_method("#{name}") do
          if settings.has_key?(name)
            settings[name]
          elsif !opts[:default].nil?
            if opts[:default].respond_to?(:call)
              opts[:default].call(self)
            else
              opts[:default]
            end
          elsif opts[:required]
            raise "setting: #{name} required in #{self}"
          end
        end
      end

      def initialize(opts = {}, from_opts = false)
        return unless opts

        opts.each do |name, value|
          if from_opts
            add_setting name, :value => from_opts === true ? value : from_opts.new(value)
          else
            schema = setting_schema(name)
            converted =
              case
              when schema.is_a?(Array) && schema[0] <= Node then value.map { |v| v.is_a?(schema[0]) ? v : schema[0].new(v) }
              when schema <= Node then value.is_a?(schema) ? value : schema.new(value)
              else
                value
              end
            assign_setting(name, converted)
          end
        end
      end

      def assign_setting(name, value); public_send("#{name}=", value) unless value.nil? end
      def safe_assign_setting(name, value); assign_setting(name, value) unless settings.has_key?(name) end
      def setting(name); public_send(name) end
      def setting_schema(name); public_send("#{name}_schema") end
      def setting_exist?(name); existing_settings.include?(name) end
      def existing_settings; self.class.class_settings + instance_settings end

      def add_setting(name, opts = {})
        return false if setting_exist?(name)

        instance_settings << name

        settings[name] = opts[:value] if opts[:value]

        define_singleton_method("#{name}_schema") { opts[:schema] || NilClass }
        define_singleton_method("#{name}=") { |value| settings[name] = value }
        define_singleton_method("#{name}") do
          if settings.has_key?(name)
            settings[name]
          elsif !opts[:default].nil?
            if opts[:default].respond_to?(:call)
              opts[:default].call(self)
            else
              opts[:default]
            end
          elsif opts[:required]
            raise "setting: #{name} required in #{self}"
          end
        end
      end

      def as_json
        existing_settings.inject({}) do |hash, name|
          value = setting(name)
          hash[name] =
            case
            when value.is_a?(Node) then value.as_json
            when value.is_a?(Array) && value[0].is_a?(Node) then value.map { |v| v.as_json }
            else value
            end unless value.nil?
          hash
        end
      end

      private

      def settings; @settings ||= {} end
      def instance_settings; @instance_settings ||= [] end
      def self.class_settings; @class_settings ||= [] end
    end
  end
end
