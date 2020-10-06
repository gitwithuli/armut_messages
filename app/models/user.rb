class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :blocker_relationships, foreign_key: :blocker_id, class_name: 'Block'
  has_many :blocker, through: :blocker_relationships, source: :blocker

  has_many :blockee_relationships, foreign_key: :blockee_id, class_name: 'Block'
  has_many :blockee, through: :blockee_relationships, source: :blockee


  def block(user_id)
    blocker_relationships.create(blockee_id: user_id)
  end

  def unblock(user_id)
    blocker_relationships.find_by(blockee_id: user_id).destroy
  end

  def is_blocked?(user_id)
    relationship = Block.find_by(blocker_id: id, blockee_id: user_id)
    return true if relationship
  end

end
