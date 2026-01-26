# frozen_string_literal: true

class CaseStudyComponentPreview < ViewComponent::Preview
  # @label Trans Dimension
  def trans_dimension
    render(CaseStudyComponent.new(partner: 'transDim'))
  end
end
