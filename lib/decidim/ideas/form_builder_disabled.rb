# frozen_string_literal: true

module Decidim
  module Ideas
    # This class is to disable print out forms in disabled state. This is used
    # when the user wants to see the idea creation form but is not yet logged
    # in.
    class FormBuilderDisabled < Decidim::Ideas::FormBuilder
      def select(attribute, choices, options = {}, html_options = {})
        html_options[:disabled] = true

        super(attribute, choices, options, html_options)
      end

      def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
        options[:disabled] = true

        super(method, options, checked_value, unchecked_value)
      end

      def radio_button(attribute, tag_value, options = {})
        options[:disabled] = true

        super(attribute, tag_value, options)
      end

      def button(value = nil, options = {}, &block)
        options[:disabled] = true

        super(value, options, &block)
      end

      private

      def field(attribute, options, html_options = nil, &block)
        options[:disabled] = true unless html_options.is_a?(Hash) && html_options[:disabled] == true

        super(attribute, options, html_options, &block)
      end
    end
  end
end
