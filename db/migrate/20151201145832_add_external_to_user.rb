class AddExternalToUser < ActiveRecord::Migration
  def change
    add_column :users, :third_party, :boolean, default: false
  end
end
