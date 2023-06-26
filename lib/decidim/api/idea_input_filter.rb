# frozen_string_literal: true

module Decidim
  module Ideas
    class IdeaInputFilter < Decidim::Core::BaseInputFilter
      include Decidim::Core::HasPublishableInputFilter

      graphql_name "IdeaFilter"
      description "A type used for filtering ideas inside a participatory space.

A typical query would look like:

```
  {
    participatoryProcesses {
      components {
        ...on Ideas {
          ideas(filter:{ publishedBefore: \"2020-01-01\" }) {
            id
          }
        }
      }
    }
  }
```
"
    end
  end
end
