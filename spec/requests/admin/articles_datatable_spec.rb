# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Articles Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  let(:admin_host) { "admin.lvh.me" }

  before { sign_in admin_user }

  # Helper to make datatable requests with proper params
  def datatable_request(params = {})
    base_params = {
      "draw" => "1",
      "start" => "0",
      "length" => "25",
      "search" => { "value" => "", "regex" => "false" },
      "columns" => {
        "0" => { "data" => "title", "name" => "title", "searchable" => "true", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "1" => { "data" => "author", "name" => "author", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "2" => { "data" => "partners", "name" => "partners", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } },
        "3" => { "data" => "published_at", "name" => "published_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "4" => { "data" => "is_draft", "name" => "is_draft", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "5" => { "data" => "updated_at", "name" => "updated_at", "searchable" => "false", "orderable" => "true", "search" => { "value" => "", "regex" => "false" } },
        "6" => { "data" => "actions", "name" => "actions", "searchable" => "false", "orderable" => "false", "search" => { "value" => "", "regex" => "false" } }
      },
      "order" => { "0" => { "column" => "5", "dir" => "desc" } }
    }
    get admin_articles_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/articles.json" do
    context "basic functionality" do
      let!(:article) { create(:article, title: "Test Article") }

      it "returns JSON with datatable structure" do
        datatable_request

        expect(response).to have_http_status(:success)
        json = response.parsed_body
        expect(json).to have_key("draw")
        expect(json).to have_key("recordsTotal")
        expect(json).to have_key("recordsFiltered")
        expect(json).to have_key("data")
      end

      it "returns all articles in data array" do
        create(:article, title: "Another Article")

        datatable_request

        json = response.parsed_body
        expect(json["data"].length).to eq(2)
      end

      it "includes article title in response data" do
        datatable_request

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("Test Article")
      end
    end

    context "search functionality" do
      let!(:matching_article) { create(:article, title: "Community Event Guide") }
      let!(:non_matching_article) { create(:article, title: "Sports News") }

      it "filters articles by search term" do
        datatable_request("search" => { "value" => "Community" })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("Community")
        expect(titles.join).not_to include("Sports")
      end

      it "search is case insensitive" do
        datatable_request("search" => { "value" => "COMMUNITY" })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("Community")
      end
    end

    context "sorting" do
      let!(:article_a) { create(:article, title: "Alpha Article") }
      let!(:article_z) { create(:article, title: "Zeta Article") }

      it "sorts by title ascending" do
        datatable_request("order" => { "0" => { "column" => "0", "dir" => "asc" } })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to match(/Alpha.*Zeta/m)
      end

      it "sorts by title descending" do
        datatable_request("order" => { "0" => { "column" => "0", "dir" => "desc" } })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to match(/Zeta.*Alpha/m)
      end
    end

    context "is_draft filter" do
      let!(:published_article) { create(:article, title: "Published Article", is_draft: false) }
      let!(:draft_article) { create(:article, title: "Draft Article", is_draft: true) }

      it "filters published articles" do
        datatable_request("filter" => { "is_draft" => "no" })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("Published Article")
        expect(titles.join).not_to include("Draft Article")
      end

      it "filters draft articles" do
        datatable_request("filter" => { "is_draft" => "yes" })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("Draft Article")
        expect(titles.join).not_to include("Published Article")
      end
    end

    context "has_partners filter" do
      let!(:partner) { create(:partner) }
      let!(:article_with_partners) do
        article = create(:article, title: "Article With Partners")
        article.partners << partner
        article
      end
      let!(:article_without_partners) { create(:article, title: "Article Without Partners") }

      it "filters articles with partners" do
        datatable_request("filter" => { "has_partners" => "yes" })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("With Partners")
        expect(titles.join).not_to include("Without Partners")
      end

      it "filters articles without partners" do
        datatable_request("filter" => { "has_partners" => "no" })

        json = response.parsed_body
        titles = json["data"].map { |d| d["title"] }
        expect(titles.join).to include("Without Partners")
        expect(titles.join).not_to include("With Partners")
      end
    end

    context "data rendering" do
      let!(:author) { create(:user, first_name: "Test", last_name: "Author") }
      let!(:partner) { create(:partner, name: "Test Partner") }
      let!(:article) do
        article = create(:article, title: "Render Test", author: author, is_draft: false, published_at: Time.zone.today)
        article.partners << partner
        article
      end

      it "renders article title cell with slug subtitle" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["title"]).to include("Render Test")
        expect(article_data["title"]).to include("render-test")
        expect(article_data["title"]).to include("href=")
      end

      it "renders author cell" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        # admin_name formats as "LASTNAME, Firstname <email>"
        expect(article_data["author"]).to include("AUTHOR, Test")
      end

      it "renders partners cell with partner name" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["partners"]).to include("Test Partner")
        expect(article_data["partners"]).to include("href=")
      end

      it "renders published_at cell" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["published_at"]).to include(Time.zone.today.strftime("%-d %b %Y"))
      end

      it "renders draft status cell with Published badge" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["is_draft"]).to include("Published")
        expect(article_data["is_draft"]).to include("bg-emerald-100")
      end

      it "renders draft status cell with Draft badge for drafts" do
        article.update!(is_draft: true)
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["is_draft"]).to include("Draft")
        expect(article_data["is_draft"]).to include("bg-amber-100")
      end

      it "renders updated_at as relative time" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["updated_at"]).to include("Today")
      end

      it "renders actions with edit button" do
        datatable_request

        json = response.parsed_body
        article_data = json["data"].find { |d| d["title"].include?("Render Test") }
        expect(article_data["actions"]).to include("Edit")
        expect(article_data["actions"]).to include("href=")
      end
    end
  end
end
