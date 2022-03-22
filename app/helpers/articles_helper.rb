# frozen_string_literal: true

# app/helpers/articles_helper.rb
module ArticlesHelper
  def options_for_partners
    policy_scope(Partner).all.order(:name).pluck(:id, :name)
  end
end
