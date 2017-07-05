class AddExternalToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :third_party, :boolean, default: false
  end
end
