class Block < ApplicationRecord
  belongs_to :blocker, foreign_key: 'blocker_id', class_name: 'User'
  belongs_to :blockee, foreign_key: 'blockee_id', class_name: 'User'
end
