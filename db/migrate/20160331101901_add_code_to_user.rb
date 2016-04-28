class AddCodeToUser < ActiveRecord::Migration
  def change
    add_column :users, :code, :string
    add_index :users, :code
  end
end
