# frozen_string_literal: true

# Step definitions for article management

Given('there is an article called {string}') do |title|
  # Use the existing partner if set, otherwise create one linked to the site's neighbourhood
  if @partner
    partner = @partner
  elsif @site
    # Create partner in site's neighbourhood so articles show up on site
    ward = @site.neighbourhoods.first || create(:riverside_ward)
    address = create(:address, neighbourhood: ward)
    partner = create(:partner, address: address)
    @site.neighbourhoods << ward unless @site.neighbourhoods.include?(ward)
  else
    partner = create(:partner)
  end
  author = @current_user || create(:root_user)
  @article = create(:article, title: title, author: author, is_draft: false)
  create(:article_partner, article: @article, partner: partner)
end

Given('there is an article called {string} authored by {string}') do |title, author_name|
  # Use the existing partner if set, otherwise create one linked to the site's neighbourhood
  if @partner
    partner = @partner
  elsif @site
    # Create partner in site's neighbourhood so articles show up on site
    ward = @site.neighbourhoods.first || create(:riverside_ward)
    address = create(:address, neighbourhood: ward)
    partner = create(:partner, address: address)
    @site.neighbourhoods << ward unless @site.neighbourhoods.include?(ward)
  else
    partner = create(:partner)
  end
  first_name, last_name = author_name.split(' ', 2)
  author = create(:root_user, first_name: first_name, last_name: last_name || '')
  @article = create(:article, title: title, author: author, is_draft: false)
  create(:article_partner, article: @article, partner: partner)
end

Given('there is an article called {string} published today') do |title|
  # Use the existing partner if set, otherwise create one linked to the site's neighbourhood
  if @partner
    partner = @partner
  elsif @site
    # Create partner in site's neighbourhood so articles show up on site
    ward = @site.neighbourhoods.first || create(:riverside_ward)
    address = create(:address, neighbourhood: ward)
    partner = create(:partner, address: address)
    @site.neighbourhoods << ward unless @site.neighbourhoods.include?(ward)
  else
    partner = create(:partner)
  end
  author = @current_user || create(:root_user)
  @article = create(:article, title: title, author: author, is_draft: false, published_at: Time.current)
  create(:article_partner, article: @article, partner: partner)
end

When('I view the article {string}') do |title|
  article = Article.find_by(title: title)
  visit "/news/#{article.id}"
end

Then('I should see the article {string}') do |title|
  expect(page).to have_content(title)
end
