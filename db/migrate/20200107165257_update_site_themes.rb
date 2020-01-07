class UpdateSiteThemes < ActiveRecord::Migration[6.0]
  def change
    set_theme 'hulme', :pink
    set_theme 'moss-side', :green
    set_theme 'rusholme', :orange
    set_theme 'moston', :blue
    set_theme 'mossley', :custom
  end

  def set_theme(slug, colour)
    site = Site.find_by(slug: slug)
    site.update(theme: colour) if site
  end
end
