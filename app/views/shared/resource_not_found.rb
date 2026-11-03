# frozen_string_literal: true

class Views::Shared::ResourceNotFound < Views::Base
  theme_scope :not_found,
              parts: {
                root: 'The page\'s column.',
                title: 'The page\'s h1.',
                body: 'The line under the title.'
              }

  def view_template
    div(**part(:root, class: 'pt-8 pb-20 text-center')) do
      h1(**part(:title, class: 'text-hero')) { t('shared.resource_not_found.title') }
      p(**part(:body, class: 'text-subhead')) { t('shared.resource_not_found.body') }
    end
  end
end
