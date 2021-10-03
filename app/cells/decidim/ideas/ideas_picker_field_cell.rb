# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeasPickerFieldCell < Decidim::ViewModel
      include Cell::ViewModel::Partial
      include Decidim::TranslatableAttributes

      delegate :current_participatory_space, :snippets, to: :controller

      def show
        # The component cannot be displayed in case there are no ideas
        # components in the same space.
        return unless ideas_component

        render
      end

      private

      def form
        model
      end

      def attached_ideas_picker_field(form, field)
        picker_options = {
          id: sanitize_to_id(field),
          class: "picker-multiple",
          name: "#{form.object_name}[#{field.to_s.sub(/s$/, "_ids")}]",
          multiple: true,
          autosort: true
        }

        url = route_proxy.search_ideas_ideas_path(
          component: ideas_component,
          format: :html
        )

        prompt_params = {
          url: url,
          text: t("attached_ideas_helper.attach_idea", scope: "decidim.ideas")
        }

        data_picker(form, field, picker_options, prompt_params) do |item|
          { url: url, text: item.title }
        end
      end

      # The normal form builder data picker does not work in cells because
      # of the partial render. This fixes the problem. Another problem is that
      # it wouldn't display the correct label. The required state of the
      # attribute also needs to be fetched from the `record_ids` attribute
      # instead of `records`.
      def data_picker(form, attribute, options = {}, prompt_params = {})
        picker_options = {
          id: "#{form.object_name}_#{attribute}",
          class: "picker-#{options[:multiple] ? "multiple" : "single"}",
          name: options[:name] || "#{form.object_name}[#{attribute}]"
        }
        picker_options[:class] += " is-invalid-input" if form.send(:error?, attribute)
        picker_options[:class] += " picker-autosort" if options[:autosort]

        items = form.object.send(attribute).collect { |item| [item, yield(item)] }

        field_attribute = attribute.to_s.sub(/s$/, "_ids")

        template = ""
        unless options[:label] == false
          label_text = field_label + form.send(:required_for_attribute, field_attribute)
          template += form.label(field_attribute, label_text)
        end
        template += render(
          partial: "decidim/widgets/data_picker.html",
          locals: {
            picker_options: picker_options,
            prompt_params: prompt_params,
            items: items
          }
        )
        template += form.send(:error_and_help_text, field_attribute, options)
        template.html_safe
      end

      def field_label
        context[:label] || t(".ideas")
      end

      # This will find the first ideas component from the same space. It does
      # not matter which component it is in case there are multiple ideas
      # components in the same space. This will be used to get the route to
      # the ideas search path.
      def ideas_component
        @ideas_component ||= Decidim::Component.order(:weight).find_by(
          participatory_space: current_participatory_space,
          manifest_name: "ideas"
        )
      end

      def route_proxy
        return unless ideas_component

        @route_proxy ||= EngineRouter.main_proxy(ideas_component)
      end
    end
  end
end
