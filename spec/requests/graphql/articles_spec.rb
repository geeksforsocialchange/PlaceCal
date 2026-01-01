# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GraphQL Articles", type: :request do
  let(:user) { create(:root_user) }
  let(:partners) { create_list(:partner, 2) }

  def execute_query(query_string, variables: {})
    post "/api/v1/graphql", params: { query: query_string, variables: variables.to_json }
    response.parsed_body
  end

  describe "articleConnection query" do
    before do
      5.times do |n|
        Article.create!(
          title: "News article #{n}",
          body: "article body text",
          author: user,
          is_draft: false,
          published_at: DateTime.current,
          partners: partners
        )
      end
    end

    let(:query) do
      <<-GRAPHQL
        query {
          articleConnection {
            edges {
              node {
                name
                headline
                author
                text
                articleBody
                datePublished
                dateCreated
                dateUpdated
                providers {
                  id
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it "returns articles with pagination" do
      result = execute_query(query)

      expect(result["errors"]).to be_nil
      edges = result["data"]["articleConnection"]["edges"]
      expect(edges.length).to eq(5)
    end

    it "includes article details" do
      result = execute_query(query)

      node = result["data"]["articleConnection"]["edges"].first["node"]
      expect(node["name"]).to be_present
      expect(node["headline"]).to be_present
      expect(node["author"]).to be_present
      expect(node["text"]).to be_present
      expect(node["articleBody"]).to be_present
    end

    it "includes provider (partner) information" do
      result = execute_query(query)

      node = result["data"]["articleConnection"]["edges"].first["node"]
      expect(node["providers"].length).to eq(partners.length)
    end
  end

  describe "articlesByTag query" do
    let(:tag) { create(:tag) }
    let(:query) do
      <<-GRAPHQL
        query($tagId: ID!) {
          articlesByTag(tagId: $tagId) {
            name
            author
            text
          }
        }
      GRAPHQL
    end
    let(:epoch) { DateTime.current.beginning_of_day }

    before do
      # Unpublished article (should not appear)
      Article.create!(
        title: "Not published article",
        body: "article body text",
        author: user
      )

      # Untagged article (should not appear)
      Article.create!(
        title: "Not tagged article",
        body: "article body text",
        author: user,
        is_draft: false,
        published_at: epoch
      )

      # Tagged articles (should appear)
      3.times do |n|
        article = Article.create!(
          title: "Tagged published article #{n}",
          body: "article body text",
          author: user,
          is_draft: false,
          published_at: epoch + (n + 1).days
        )
        article.tags << tag
      end
    end

    it "returns only published articles with tag" do
      result = execute_query(query, variables: { tagId: tag.id })

      expect(result["errors"]).to be_nil
      articles = result["data"]["articlesByTag"]
      expect(articles.length).to eq(3)
    end

    it "sorts articles by title" do
      result = execute_query(query, variables: { tagId: tag.id })

      articles = result["data"]["articlesByTag"]
      expect(articles.first["name"]).to eq("Tagged published article 0")
      expect(articles.last["name"]).to eq("Tagged published article 2")
    end
  end

  describe "articlesByPartnerTag query" do
    let(:tag) { create(:tag) }
    let(:query) do
      <<-GRAPHQL
        query($tagId: ID!) {
          articlesByPartnerTag(tagId: $tagId) {
            name
            author
            text
          }
        }
      GRAPHQL
    end
    let(:partner) { create(:partner) }
    let(:epoch) { DateTime.current.beginning_of_day }

    before do
      partner.tags << tag

      # Unpublished article (should not appear)
      Article.create!(
        title: "Not published article",
        body: "article body text",
        author: user
      )

      # Untagged partner article (should not appear)
      Article.create!(
        title: "Not tagged partner article",
        body: "article body text",
        author: user,
        is_draft: false,
        published_at: epoch
      )

      # Articles from tagged partner (should appear)
      5.times do |n|
        article = Article.create!(
          title: "Partner article #{n}",
          body: "article body text",
          author: user,
          is_draft: false,
          published_at: epoch + (n + 1).days
        )
        article.partners << partner
      end
    end

    it "returns only published articles from partners with tag" do
      result = execute_query(query, variables: { tagId: tag.id })

      expect(result["errors"]).to be_nil
      articles = result["data"]["articlesByPartnerTag"]
      expect(articles.length).to eq(5)
    end

    it "sorts articles by title" do
      result = execute_query(query, variables: { tagId: tag.id })

      articles = result["data"]["articlesByPartnerTag"]
      expect(articles.first["name"]).to eq("Partner article 0")
      expect(articles.last["name"]).to eq("Partner article 4")
    end
  end

  describe "ping query" do
    let(:query) do
      <<-GRAPHQL
        query {
          ping
        }
      GRAPHQL
    end

    it "returns a greeting with current time" do
      result = execute_query(query)

      expect(result["errors"]).to be_nil
      ping = result["data"]["ping"]
      expect(ping).to match(/^Hello World! The time is \d{4}-\d{2}-\d{2}/)
    end
  end
end
