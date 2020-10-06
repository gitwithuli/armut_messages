class CreateBlocks < ActiveRecord::Migration[6.0]
  def change
    create_table :blocks do |t|
      t.integer 'blocker_id', null: false
      t.integer 'blockee_id', null: false

      t.timestamps null: false
    end

    add_index :blocks, :blocker_id
    add_index :blocks, :blockee_id
    add_index :blocks, [:blocker_id, :blockee_id], unique: true
  end
end
