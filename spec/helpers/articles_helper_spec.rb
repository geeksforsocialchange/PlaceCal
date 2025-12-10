# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ArticlesHelper, type: :helper do
  describe '#article_summary_text' do
    it 'handles null value' do
      article = build(:article, body: nil)

      output = helper.article_summary_text(article)
      expect(output).to eq('')
    end

    it 'handles short text' do
      article = build(:article, body: 'This is a body text')

      output = helper.article_summary_text(article)
      expect(output.length).to eq(19)
    end

    it 'trims long text' do
      article = build(:article, body: 'a' * 250)

      output = helper.article_summary_text(article)
      expect(output.length).to eq(200)
    end
  end
end
