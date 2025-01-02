# frozen_string_literal: true

module Decidim
  module Ideas
    # Customized view methods for Decidim forms.
    module FormHelper
      # A custom form for that injects client side validations with Abide.
      #
      # Customized from Decidim core to avoid on blur validations which are
      # not very useful for the users.
      #
      # record - The object to build the form for.
      # options - A Hash of options to pass to the form builder.
      # &block - The block to execute as content of the form.
      #
      # Returns a String.
      def decidim_form_for(record, options = {}, &)
        options[:data] ||= {}
        options[:data].update(
          abide: true,
          "live-validate" => false,
          "validate-on-blur" => false,
          "validate-on" => "formSubmit"
        )

        options[:html] ||= {}
        options[:html].update(novalidate: true)

        # Generally called by form_for but we need the :url option generated
        # already before that.
        #
        # See:
        # https://github.com/rails/rails/blob/master/actionview/lib/action_view/helpers/form_helper.rb#L459
        if record.is_a?(ActiveRecord::Base)
          object = record.is_a?(Array) ? record.last : record
          format = options[:format]
          apply_form_for_options!(record, object, options) if object
          options[:format] = format if format
        end

        output = ""
        output += base_error_messages(record).to_s
        output += form_for(record, options, &).to_s

        output.html_safe
      end
    end
  end
end
