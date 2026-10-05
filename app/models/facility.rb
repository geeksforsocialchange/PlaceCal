# frozen_string_literal: true

# == Schema Information
#
# Table name: tags
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string           not null
#  system_tag  :boolean          default(FALSE), not null
#  type        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_tags_name_type  (name,type) UNIQUE
#  index_tags_slug_type  (slug,type) UNIQUE
#
class Facility < Tag
end
