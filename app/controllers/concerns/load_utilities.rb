module LoadUtilities
  extend ActiveSupport::Concern

  included do
    def turfs
      if user_policy.check_root_role? 
        @turfs = Turf.all
      else
        @turfs = current_user.turfs
      end
    end
  end
end