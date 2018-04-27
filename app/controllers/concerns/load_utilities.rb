module LoadUtilities
  extend ActiveSupport::Concern

  included do
    def turfs
    	if user_policy.check_root_role? 
    		@turfs = Turf.all.collect{ |t| [t.name, t.id] }
    	else
       	@turfs = current_user.turfs.collect{ |t| [t.name, t.id] }
    	end
    end
  end
end