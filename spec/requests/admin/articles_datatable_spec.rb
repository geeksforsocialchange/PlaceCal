# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Articles Datatable JSON API", type: :request do
  let(:admin_user) { create(:root_user) }
  # Define columns for this datatable
  let(:datatable_columns) do
    [
      { data: :title, searchable: true, orderable: true },
      { data: :author, orderable: true },
      { data: :partners },
      { data: :published_at, orderable: true },
      { data: :is_draft, orderable: true },
      { data: :updated_at, orderable: true },
      { data: :actions }
    ]
  end

  before { sign_in admin_user }

  def datatable_request(params = {})
    base_params = build_datatable_params(columns: datatable_columns, default_sort_column: 5)
    get admin_articles_url(format: :json, host: admin_host), params: base_params.deep_merge(params)
  end

  describe "GET /admin/articles.json" do
    context "basic functionality" do
      let!(:article) { create(:article, title: "Test Article") }

      it_behaves_like "datatable JSON structure"

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

      it_behaves_like "datatable search",
                      search_field: :title,
                      matching_value: "Community",
                      non_matching_value: "Sports"
    end

    context "sorting" do
      let!(:article_a) { create(:article, title: "Alpha Article") }
      let!(:article_z) { create(:article, title: "Zeta Article") }

      it_behaves_like "datatable sorting",
                      column_index: 0,
                      field: :title,
                      first_value: "Alpha",
                      last_value: "Zeta"
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

      it_behaves_like "datatable yes/no filter",
                      filter_name: "has_partners",
                      field: :title,
                      yes_value: "With Partners",
                      no_value: "Without Partners"
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
        expect(article_data["author"]).to include("Test Author")
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

      it_behaves_like "datatable renders relative time", field: :updated_at
      it_behaves_like "datatable renders edit button"
    end
  end
end
