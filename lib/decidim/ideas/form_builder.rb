# frozen_string_literal: true

module Decidim
  module Ideas
    class FormBuilder < Decidim::FormBuilder
      # This is a wrapper method to print out correctly style "plain" labels
      # without the fields. The `field` method does not print out the required
      # notification and the `custom_field` method is a private method.
      # Therefore, this method is necessary for printing out consistent labels
      # when they are controlled separately from the field inputs.
      def plain_label(attribute, text = nil, options = {})
        return "".html_safe if text == false

        if text.is_a?(Hash)
          options = text
          text = nil
        end

        show_required = options.delete(:show_required)
        show_required = true if show_required.nil?

        text = default_label_text(object, attribute) if text.nil? || text == true
        text += required_for_attribute(attribute) if show_required

        label(attribute, text, options)
      end

      # We only want to display the top-level categories.
      def categories_for_select(scope)
        sorted_main_categories = scope.includes(:subcategories).sort_by do |category|
          [category.weight, translated_attribute(category.name, category.participatory_space.organization)]
        end

        sorted_main_categories.flat_map do |category|
          parent = [[translated_attribute(category.name, category.participatory_space.organization), category.id]]

          parent
        end
      end

      private

      # Private: Builds a Hash of options to be injected at the HTML output as
      # HTML5 validations.
      #
      # attribute - The String name of the attribute to extract the validations.
      # options - A Hash of options to extract validations.
      #
      # Returns a Hash.
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def extract_validations(attribute, options)
        min_length = options.delete(:minlength) || length_for_attribute(attribute, :minimum) || 0
        max_length = options.delete(:maxlength) || length_for_attribute(attribute, :maximum)

        validation_options = {}
        # Remove the pattern to disable errors on empty fields.
        validation_options[:pattern] = "^(.|[\n\r]){#{min_length},#{max_length}}$" if min_length.to_i.positive? || max_length.to_i.positive?
        validation_options[:required] = options[:required] || attribute_required?(attribute)
        validation_options[:minlength] ||= min_length if min_length.to_i.positive?
        validation_options[:maxlength] ||= max_length if max_length.to_i.positive?
        validation_options
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Private: Tries to find a length validator in the form object.
      #
      # attribute - The attribute to look for the validations.
      # type      - A Symbol for the type of length to fetch. Currently only :minimum & :maximum are supported.
      #
      # Returns an Integer or Nil.
      def length_for_attribute(attribute, type)
        length_validator = find_validator(attribute, ActiveModel::Validations::LengthValidator)
        return length_validator.options[type] if length_validator

        length_validator = find_validator(attribute, IdeaLengthValidator)
        if length_validator
          length = length_validator.options[type]
          return length.call(object) if length.respond_to?(:call)

          return length
        end

        nil
      end
    end
  end
end
