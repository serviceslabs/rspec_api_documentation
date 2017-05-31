module RspecApiDocumentation
  module Swaggers
    class Node
      def self.add_setting(name, opts = {})
        class_settings << name

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

      def initialize(opts = {})
        opts.each { |k, v| public_send("#{k}=", v) }
        yield self if block_given?
      end

      def add_setting(name, opts = {})
        return false if setting_exist?(name)

        instance_settings << name

        settings[name] = opts[:value] if opts[:value]
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

      def setting_exist?(name)
        existing_settings.include?(name)
      end

      def as_json
        existing_settings.inject({}) do |hash, setting|
          value = public_send(setting)
          hash[setting] =
            case
            when value.is_a?(Node) then value.as_json
            when value.is_a?(Array) && value[0].is_a?(Node) then value.map { |v| v.as_json }
            else value
            end unless value.nil?
          hash
        end
      end

      # Array of all existing settings
      def existing_settings
        self.class.class_settings + instance_settings
      end

      private

      # Storage of settings values
      def settings
        @settings ||= {}
      end

      # Array of existing settings for certain instance of class
      def instance_settings
        @instance_settings ||= []
      end

      # Array of existing settings for any instance of class
      def self.class_settings
        @class_settings ||= []
      end
    end
  end
end
