# FAST AND EASY CREATION OF PLUGINS FOR THECORE

Just use the template system provided by rails, it must point to the template file created by me that can reside even on the web

```shell
rails plugin new gemname -T --full -m 'https://www.taris.it/thecore_bins/new_thecore_plugin.rb'
```

Then add all the models you need and run the generator:

```shell
rails g thecorize_plugin $(basename $(pwd)) [-g gitserver]
```

The -g switch is completely optional.

Replacing gitserver with the full URL to git server.

If you add other models, you can rerun the generator as many times you need.

# FAST AND EASY CREATION OF A NEW RAILS APP COMPATIBLE WITH THECORE

Just use the template system provided by rails, it must point to the template file created by me that can reside even on the web

```shell
rails new appname --database --database=postgresql -m 'https://www.taris.it/thecore_bins/new_thecore_app.rb'
```

# APPLY NEW GITIGNORE ADDS

```shell
git ls-files -ci --exclude-standard -z | xargs -0r git rm --cached
git push
```

---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
# LONGER STORY (HOW I GOT TO THOSE TWO SIMPLE COMMANDS ABOVE)

If you'd like to mess manually with your plugins and apps, here is what I do into the template files

# CONFIGURE FULL ENGINES THAT ARE BASED ON THE CORE

This is all based on the creation of several engines (full) that could be used as bricks to build an application from the ground, having some functionalities already tested and reusable.

```shell
# rails _4.2.7.1_ plugin new gemname --full
rails plugin new gemname --full
```

Init git, add a .gitignore, commit gitignore.

Remove from gemname.gemspec the dependency to rails and sqlite3,

```ruby
s.add_dependency "rails"
s.add_development_dependency "sqlite3"
```

then add to gemname.gemspec:

```ruby
s.add_dependency "thecore"
```

Add to Gemfile (to allow development testing):

```ruby
gem 'thecore', path: '../../thecore_project/thecore'
```

Remember to add to the lib/{enginename}/engine.rb the loading of it's db migrations:

```ruby
module KindergartenModules
  class Engine < ::Rails::Engine
    initializer "kindergarten_modules.add_to_migrations" do |app|
      unless app.root.to_s == root.to_s
        # APPEND TO MAIN APP MIGRATIONS FROM THIS GEM
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
```

And use migrations, not seeding, for adding data to the DB, copy the class (activerecord) definition of the model inside the migrations that adds data to be sure to have a class (model) that surely works for this migration.

Commit git, happy coding.

# USING ATTACHMENTS

For the attachemnts is used paperclip, if you want to have a good starting point to make rails_admin understand an attachment field, you have to define a model like that (the field is called asset):

```ruby
class Foo < ActiveRecord::Base
  # ASSET
  has_attached_file :asset, styles: { thumb: "100x100#",small: "150x150>", medium: "200x200" }
  validates_attachment_content_type :asset, content_type: /\Aimage\/.*\Z/
  # add a delete_<asset_name> method:
  attr_accessor :delete_asset
  before_validation { self.asset.clear if self.delete_asset == '1' }
end
```

And the migration:

```ruby
class AddAttachmentAssetToBullettinBoards < ActiveRecord::Migration
  def self.up
    change_table :bullettin_boards do |t|
      t.attachment :asset
    end
  end

  def self.down
    remove_attachment :bullettin_boards, :asset
  end
end
```

No other things are needed in rails_admin configuration, it's all automagically recognized.

# EXTEND RAILS_ADMIN SECTION

IMPORTANT: To extend rails admin section in model, directly, instead of using concerns, I can
extend the included method. Be sure to use a different module name, otherwise it will be overwritten
See thecore_settings_rails_admin_model_extensions.rb initializer for a reference (gem: thecore_settings)
on how to extend rails_admin section of a model previously defined (say it's defined in another gem)
