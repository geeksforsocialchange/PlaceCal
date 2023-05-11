# frozen_string_literal: true

require 'yaml'

class CaseStudyComponent < ViewComponent::Base
  def initialize(partner:)
    super
    partner_info = YAML.load_file(
      File.join(__dir__, 'case_study_component/case_study_data.yml')
    )[partner]

    @partner = partner_info['partner']
    @logo_src = partner_info['logo_src']
    @image_src = partner_info['image_src']
    @image_alt = partner_info['image_alt']
    @partner_url = partner_info['partner_url']
    @link_url = partner_info['link_url']
    @description = partner_info['description']
    @pull_quote = partner_info['pull_quote']
  end
end
