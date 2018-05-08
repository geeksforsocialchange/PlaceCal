module LoadUtilities
  extend ActiveSupport::Concern

  included do
    def turfs
       @turfs = current_user.turfs.collect{ |t| [t.name, t.id] }
    end
  end
end