module Admin
  class PagesController < Admin::ApplicationController
    before_action :secretary_authenticate

    def home
      @partners = Partner.find_by_sql("SELECT DISTINCT(partners.*) FROM partners INNER JOIN partners_turfs ON partners.id = partners_turfs.partner_id WHERE partners_turfs.turf_id IN (SELECT turf_id FROM turfs_users WHERE turfs_users.user_id = #{current_user.id}) ;")
      @places = Place.find_by_sql("SELECT DISTINCT(places.*) FROM places INNER JOIN places_turfs ON places.id = places_turfs.place_id WHERE places_turfs.turf_id IN (SELECT turf_id FROM turfs_users WHERE turfs_users.user_id = #{current_user.id}) ;  ");
      @turfs = current_user.turfs

    end

  end
end
