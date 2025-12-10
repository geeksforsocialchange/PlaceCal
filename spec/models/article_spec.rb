# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Article do
  let(:article) { create(:article) }
  let(:article_draft) { create(:article_draft) }

  describe 'validations' do
    it 'is valid' do
      expect(article).to be_valid
    end

    it 'requires title to be present' do
      article.title = ''
      expect(article).not_to be_valid
    end

    it 'requires body to be present' do
      article.body = ''
      expect(article).not_to be_valid
    end
  end

  describe 'published_at' do
    it 'updates correctly when is_draft is set' do
      expect(article_draft.published_at).to be_nil

      article_draft.is_draft = false
      article_draft.save!

      expect(article_draft.published_at).to be_present
    end
  end

  describe '.with_tags' do
    it 'finds articles tagged with tag' do
      user = create(:user)
      tag = create(:tag)

      # articles without tag
      4.times do |n|
        Article.create!(
          title: "Article title no. #{n}",
          body: 'lorem ipsum ...',
          author: user
        )
      end

      # with tags
      2.times do |n|
        article = Article.create!(
          title: "Article title no. #{n}",
          body: 'lorem ipsum ...',
          author: user
        )
        article.tags << tag
      end

      found = Article.with_tags(tag.id)
      expect(found.count).to eq(2)
    end
  end

  describe '.with_partner_tag' do
    it 'finds articles from partners with a given tag' do
      user = create(:user)
      tag = create(:tag)
      partner = create(:partner)
      partner.tags << tag

      # articles not by partner (no tag)
      3.times do |n|
        Article.create!(
          title: "Article title no. #{n}",
          body: 'lorem ipsum ...',
          author: user
        )
      end

      # articles by tagged partner
      5.times do |n|
        article = Article.create!(
          title: "Article title no. #{n}",
          body: 'lorem ipsum ...',
          author: user
        )
        article.partners << partner
      end

      found = Article.with_partner_tag(tag.id)
      expect(found.length).to eq(5)
    end
  end

  describe '.for_site' do
    let(:neighbourhood_1) { create(:riverside_ward) }
    let(:neighbourhood_2) { create(:oldtown_ward) }
    let(:author) { create(:root) }

    it 'returns articles for site (via neighbourhood)' do
      site = create(:site)
      site.neighbourhoods << neighbourhood_1
      site.neighbourhoods << neighbourhood_2

      partner_1 = create(:partner, address: create(:address, neighbourhood: neighbourhood_1))
      partner_2 = create(:partner, address: create(:address, neighbourhood: neighbourhood_2))

      # from first partner
      2.times do |n|
        partner_1.articles.create!(
          title: "#{n} Article from Partner 1",
          is_draft: nil,
          body: 'lorem ipsum dorem ditsum',
          author: author
        )
      end

      # from second partner
      3.times do |n|
        partner_2.articles.create!(
          title: "#{n} Article from Partner 2",
          is_draft: nil,
          body: 'lorem ipsum dorem ditsum',
          author: author
        )
      end

      found = Article.for_site(site).select(:id)
      expect(found.count).to eq(5)
    end

    it 'returns articles with site tags applied' do
      tag = create(:tag)

      site = create(:site)
      site.tags << tag
      site.validate!

      3.times do |n|
        article = Article.create!(
          title: "#{n} Article with tag",
          is_draft: nil,
          body: 'lorem ipsum dorem ditsum',
          author: author
        )
        article.tags << tag
        article.validate!
      end

      found = Article.for_site(site)
      expect(found.count).to eq(3)
    end

    it 'finds articles by both neighbourhood and tag' do
      site = create(:site)

      site.neighbourhoods << neighbourhood_1

      partner = create(:partner, address: create(:address, neighbourhood: neighbourhood_1))

      3.times do |n|
        partner.articles.create!(
          title: "#{n} Article from Partner by neighbourhood",
          is_draft: nil,
          body: 'lorem ipsum dorem ditsum',
          author: author
        )
      end

      tag = create(:tag)
      site.tags << tag

      5.times do |n|
        article = Article.create!(
          title: "#{n} Article with tag",
          is_draft: nil,
          body: 'lorem ipsum dorem ditsum',
          author: author
        )
        article.tags << tag
      end

      found = Article.for_site(site).select(:id)
      expect(found.count).to eq(8)
    end
  end

  describe 'body_html' do
    it 'is rendered from body' do
      art = create(:article)
      art.body = 'A body of text about something'
      art.save!
      expect(art.body_html).to be_present
    end
  end
end
