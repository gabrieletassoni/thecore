class AddCodeToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :code, :string
    add_index :users, :code
  end
end
