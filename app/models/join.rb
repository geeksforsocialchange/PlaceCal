# frozen_string_literal: true

class Join
  include ActiveModel::Model

  attr_accessor :name, :email, :phone, :job_title, :job_org, :area,
                :ringback, :more_info, :why

  validates :name, :email, :why, presence: true

  def submit
    if valid?
      JoinMailer.join_us(self).deliver
      true
    else
      false
    end
  end
end
