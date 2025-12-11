# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Articles', type: :request do
  let(:admin_host) { 'admin.lvh.me' }

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

  describe 'GET /admin/articles/new' do
    context 'as a neighbourhood admin' do
      before { sign_in neighbourhood_admin }

      it 'shows partner in partner selector' do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        expect(response.body).to include(partner.name)
      end

      it 'preselects author as current user' do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # admin_name uses angle brackets which are HTML-escaped
        expect(response.body).to include(CGI.escapeHTML(neighbourhood_admin.admin_name))
      end
    end

    context 'as a partner admin' do
      before { sign_in partner_admin }

      it 'preselects their partner' do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # Partner should be in the selector
        expect(response.body).to include(partner.name)
      end

      it 'preselects author as current user' do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # admin_name uses angle brackets which are HTML-escaped
        expect(response.body).to include(CGI.escapeHTML(partner_admin.admin_name))
      end
    end

    context 'as an editor' do
      before { sign_in editor_user }

      it 'preselects author as current user' do
        get new_admin_article_url(host: admin_host)
        expect(response).to be_successful
        # admin_name uses angle brackets which are HTML-escaped
        expect(response.body).to include(CGI.escapeHTML(editor_user.admin_name))
      end
    end
  end

  describe 'POST /admin/articles' do
    context 'with bad image upload' do
      before { sign_in root_user }

      it 'shows error for invalid image type' do
        new_article_params = {
          title: 'a new article',
          body: 'alpha beta cappa delta epsilon foxtrot etc',
          author_id: root_user.id,
          article_image: fixture_file_upload('bad-cat-picture.bmp')
        }

        post admin_articles_url(host: admin_host), params: { article: new_article_params }

        expect(response).not_to be_redirect
        expect(response.body).to include('error prohibited this Article from being saved')
        expect(response.body).to include('Article image')
        expect(response.body).to include('not allowed to upload')
        expect(response.body).to include('bmp')
      end
    end
  end

  describe 'PUT /admin/articles/:id' do
    let(:article) { create(:article) }

    context 'with bad image upload' do
      before { sign_in root_user }

      it 'shows error for invalid image type' do
        article_params = {
          title: article.title,
          body: article.body,
          author_id: article.author_id,
          article_image: fixture_file_upload('bad-cat-picture.bmp')
        }

        put admin_article_url(article, host: admin_host), params: { article: article_params }

        expect(response).not_to be_redirect
        expect(response.body).to include('error prohibited this Article from being saved')
        expect(response.body).to include('Article image')
        expect(response.body).to include('not allowed to upload')
        expect(response.body).to include('bmp')
      end
    end
  end
end
