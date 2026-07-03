# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Articles", type: :request do
  let!(:root_user) { create(:root_user) }
  let!(:editor_user) { create(:editor_user) }
  let!(:citizen_user) { create(:citizen_user) }
  let!(:partner_admin) { create(:partner_admin) }
  let(:partner) { partner_admin.partners.first }

  # Neighbourhood admin with partner in their district
  let!(:neighbourhood_admin) do
    admin = create(:neighbourhood_admin)
    # Put the partner's address in the admin's neighbourhood
    partner.address.update!(neighbourhood: admin.neighbourhoods.first)
    admin
  end

  describe "GET /admin/articles/new" do
    context "as a neighbourhood admin" do
      before { sign_in neighbourhood_admin }

      it "shows partner in partner selector" do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner.name)
      end

      it "preselects author as current user" do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # admin_name uses angle brackets which are HTML-escaped
        expect(response.body).to include(CGI.escapeHTML(neighbourhood_admin.admin_name))
      end
    end

    context "as a partner admin" do
      before { sign_in partner_admin }

      it "preselects their partner" do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # Partner should be in the selector
        expect(response.body).to include(partner.name)
      end

      it "preselects author as current user" do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # admin_name uses angle brackets which are HTML-escaped
        expect(response.body).to include(CGI.escapeHTML(partner_admin.admin_name))
      end
    end

    context "as an editor" do
      before { sign_in editor_user }

      it "preselects author as current user" do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # admin_name uses angle brackets which are HTML-escaped
        expect(response.body).to include(CGI.escapeHTML(editor_user.admin_name))
      end
    end
  end

  describe "editor role end-to-end (issue #2045 regression)" do
    before { sign_in editor_user }

    let(:other_partner_article) { create(:article, partners: [create(:partner)]) }

    it "shows the Articles link in the admin nav" do
      get "http://#{admin_host}"
      expect(response).to be_successful
      expect(response.body).to include(admin_articles_path)
    end

    it "can view the articles index" do
      get admin_articles_url(host: admin_host)
      expect(response).to be_successful
    end

    it "offers every partner in the new-article form" do
      partner
      get new_admin_article_url(host: admin_host)
      expect(response).to be_successful
      expect(response.body).to include(partner.name)
    end

    it "can edit another partner's article and still see all partner options" do
      get edit_admin_article_url(other_partner_article, host: admin_host)
      expect(response).to be_successful
      expect(response.body).to include(partner.name)
    end

    it "can create an article attached to any partner" do
      post admin_articles_url(host: admin_host), params: {
        article: {
          title: "Editor-created article",
          body: "Words about a community group",
          author_id: editor_user.id,
          partner_ids: [partner.id]
        }
      }

      expect(response).to redirect_to(admin_articles_path)
      expect(Article.find_by(title: "Editor-created article").partners).to contain_exactly(partner)
    end

    it "can update another partner's article" do
      put admin_article_url(other_partner_article, host: admin_host), params: {
        article: { title: "Updated by editor" }
      }

      expect(response).to be_redirect
      expect(other_partner_article.reload.title).to eq("Updated by editor")
    end

    it "can delete another partner's article" do
      delete admin_article_url(other_partner_article, host: admin_host)

      expect(response).to be_redirect
      expect(Article.exists?(other_partner_article.id)).to be false
    end
  end

  describe "record-level authorization for non-staff" do
    let!(:foreign_article) { create(:article, title: "Someone else's news", partners: [create(:partner)]) }

    context "as a partner admin" do
      before { sign_in partner_admin }

      it "cannot open the edit form for another partner's article" do
        get edit_admin_article_url(foreign_article, host: admin_host)

        expect(response).to redirect_to(admin_root_path)
      end

      it "cannot update another partner's article" do
        put admin_article_url(foreign_article, host: admin_host), params: {
          article: { title: "Hijacked" }
        }

        expect(response).to redirect_to(admin_root_path)
        expect(foreign_article.reload.title).to eq("Someone else's news")
      end

      it "cannot delete another partner's article" do
        delete admin_article_url(foreign_article, host: admin_host)

        expect(response).to redirect_to(admin_root_path)
        expect(Article.exists?(foreign_article.id)).to be true
      end

      it "cannot create an article for another partner" do
        other_partner = create(:partner)

        post admin_articles_url(host: admin_host), params: {
          article: { title: "Planted article", body: "Some words", author_id: partner_admin.id,
                     partner_ids: [other_partner.id] }
        }

        expect(response).to redirect_to(admin_root_path)
        expect(Article.find_by(title: "Planted article")).to be_nil
      end
    end

    it "still allows editors to manage any article" do
      sign_in editor_user

      put admin_article_url(foreign_article, host: admin_host), params: {
        article: { title: "Edited by staff" }
      }

      expect(response).to be_redirect
      expect(foreign_article.reload.title).to eq("Edited by staff")
    end
  end

  describe "partner requirement for non-staff authors" do
    context "as a partner admin" do
      before { sign_in partner_admin }

      it "rejects creating an article with no partners" do
        post admin_articles_url(host: admin_host), params: {
          article: { title: "Orphan article", body: "Some words", author_id: partner_admin.id, partner_ids: [""] }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("at least one partner")
        expect(Article.find_by(title: "Orphan article")).to be_nil
      end

      it "creates an article linked to their partner" do
        post admin_articles_url(host: admin_host), params: {
          article: { title: "Partner news", body: "Some words", author_id: partner_admin.id, partner_ids: [partner.id] }
        }

        expect(response).to redirect_to(admin_articles_path)
        expect(Article.find_by(title: "Partner news").partners).to contain_exactly(partner)
      end

      it "rejects removing every partner on update" do
        article = create(:article, partners: [partner])

        put admin_article_url(article, host: admin_host), params: {
          article: { title: article.title, partner_ids: [""] }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(article.reload.partners).to contain_exactly(partner)
      end
    end

    it "allows editors to create partner-less platform posts" do
      sign_in editor_user

      post admin_articles_url(host: admin_host), params: {
        article: { title: "Platform announcement", body: "Some words", author_id: editor_user.id, partner_ids: [""] }
      }

      expect(response).to redirect_to(admin_articles_path)
      expect(Article.find_by(title: "Platform announcement")).to be_present
    end
  end

  describe "POST /admin/articles" do
    context "with bad image upload" do
      before { sign_in root_user }

      it "shows error for invalid image type" do
        new_article_params = {
          title: "a new article",
          body: "alpha beta cappa delta epsilon foxtrot etc",
          author_id: root_user.id,
          article_image: fixture_file_upload("bad-cat-picture.bmp")
        }

        post admin_articles_url(host: admin_host), params: { article: new_article_params }

        expect(response).not_to be_redirect
        expect(response.body).to include("error prohibited this Article from being saved")
        expect(response.body).to include("Article image")
        expect(response.body).to include("not allowed to upload")
        expect(response.body).to include("bmp")
      end
    end
  end

  describe "PUT /admin/articles/:id" do
    let(:article) { create(:article) }

    context "with bad image upload" do
      before { sign_in root_user }

      it "shows error for invalid image type" do
        article_params = {
          title: article.title,
          body: article.body,
          author_id: article.author_id,
          article_image: fixture_file_upload("bad-cat-picture.bmp")
        }

        put admin_article_url(article, host: admin_host), params: { article: article_params }

        expect(response).not_to be_redirect
        expect(response.body).to include("error prohibited this Article from being saved")
        expect(response.body).to include("Article image")
        expect(response.body).to include("not allowed to upload")
        expect(response.body).to include("bmp")
      end
    end
  end
end
