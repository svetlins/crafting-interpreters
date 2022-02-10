module ALox
  module AstNodeDSL
    def self.included(base)
      base.extend self
    end

    class DSLEnvironment
      attr_reader :primary_fields, :additional_fields

      def initialize
        @primary_fields = []
        @additional_fields = []
      end

      def method_missing(name, *args, **kwargs)
        fail if @primary_fields.include?(name)

        @primary_fields << name
      end

      def respond_to_missing?(*) = true

      def additional(*names)
        names.each do |name|
          fail if @additional_fields.include?(name)
          @additional_fields << name
        end
      end
    end

    def define_node(&block)
      env = DSLEnvironment.new
      env.instance_eval(&block)

      Class.new do
        attr_reader(*env.primary_fields)
        attr_accessor(*env.additional_fields)

        define_method :initialize do |*args|
          if args.size != env.primary_fields.size
            fail ArgumentError,
              "exactly #{present_fields_list(env.primary_fields)} needed"
          end

          env.primary_fields.each_with_index do |primary_field_name, i|
            instance_variable_set(:"@#{primary_field_name}", args[i])
          end

          env.additional_fields.each { |f| instance_variable_set(:"@#{f}", nil) }
        end

        define_method :accept do |visitor|
          visitor.public_send(:"visit_#{underscore(self.class.name)}", self)
        end

        private

        def present_fields_list(fields)
          return "no fields" if fields.empty?
          return "`#{fields.first}`" if fields.size == 1

          fields[0..-2].map { |f| "`#{f}`" }.join(", ") + " and `#{fields[-1]}`"
        end

        def underscore(camel_cased_word)
          word = camel_cased_word.split("::").last
          word = word.gsub(/([A-Z]+)(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) { ($1 || $2) + "_" }
          word = word.tr("-", "_")
          word = word.downcase
          word
        end
      end
    end
  end
end
