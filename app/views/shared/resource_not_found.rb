# frozen_string_literal: true

class Views::Shared::ResourceNotFound < Views::Base
  def view_template
    div(class: 'pt-8 pb-20 text-center') do
      h1(class: 'text-hero') { t('shared.resource_not_found.title') }
      p(class: 'text-subhead') { t('shared.resource_not_found.body') }
    end
  end
end
