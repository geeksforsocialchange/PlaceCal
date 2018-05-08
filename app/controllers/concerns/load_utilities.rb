module LoadUtilities
 extend ActiveSupport::Concern

  included do
    def set_turfs
      if current_user&.role&.root?
         @turfs = Turf.all
       else
         @turfs = current_user&.turfs
      end
    end
  end
end
