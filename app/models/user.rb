# app/models/user.rb
class User < ApplicationRecord
  extend Enumerize
  enumerize :role, in: %i[admin moderator partner secretary]
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  has_and_belongs_to_many :partners
  has_and_belongs_to_many :turfs

  validates_presence_of :email
  validates_uniqueness_of :email


  def full_name
    (first_name || "") + " " + (last_name || "")
  end

end
