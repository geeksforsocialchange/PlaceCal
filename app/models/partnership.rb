# frozen_string_literal: true

class Partnership < Tag
  scope :users_partnerships, lambda { |user|
                               return Partnership.all if user.role == 'root' && !user.partnership_admin?

                               user.partnerships
                             }
end
