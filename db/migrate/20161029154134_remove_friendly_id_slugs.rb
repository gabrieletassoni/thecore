class CreateFriendlyIdSlugs < ActiveRecord::Migration
  def change
    drop_table :friendly_id_slugs
  end
end
