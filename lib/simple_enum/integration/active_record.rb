require 'active_record'
require 'active_support/concern'

require 'simple_enum/dirty'

module SimpleEnum
  module Integration

    # Public: Provide integration for active record, allows
    # to use dirty and bang methods, whooop whoop.
    module ActiveRecord
      extend ActiveSupport::Concern

      module ClassMethods
        def simple_enum_initialization_callback(attribute)
          attribute.enum.keys.each do |key|
            simple_enum_generated_feature_methods.module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{attribute.prefix}#{key}!                                   # def female!
                update_enum_column(#{attribute.name.inspect}, #{key.inspect})  #   update_enum_column(:genders, :female)
              end                                                              # end
            RUBY
          end

          super
        end
      end

      def update_enum_column(attribute, key)
        value = write_enum_attribute(attribute, key)
        column = simple_enum_attributes[attribute].column
        update_column(column, value)
      end

      private

      def read_enum_attribute_before_conversion(attribute)
        read_attribute(simple_enum_attributes[attribute].column)
      end

      def write_enum_attribute_after_conversion(attribute, value)
        write_attribute(simple_enum_attributes[attribute].column, value)
      end
    end
  end
end

# Extend ActiveRecord::Base
ActiveRecord::Base.send(:include, SimpleEnum::Attributes)
ActiveRecord::Base.send(:extend,  SimpleEnum::Dirty)
ActiveRecord::Base.send(:include, SimpleEnum::Integration::ActiveRecord)
