class ThecorizeModelsGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  desc "Make migrations usable into main app"
  def migrations_to_main_app
    dir = File.join("lib", engine_name)
    inside dir do |dir_path|
      file = File.join(dir_path,"engine.rb")
      if is_engine?(file) && !has_add_to_migrations_declaration?(file)
        say "Adding migration reflection into engine.rb of #{engine_name}", :green
        inject_into_file file, after: "class Engine < ::Rails::Engine\n" do
"
    initializer '#{engine_name}.add_to_migrations' do |app|
      unless app.root.to_s == root.to_s
        # APPEND TO MAIN APP MIGRATIONS FROM THIS GEM
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

"
        end
      end
    end
  end

  desc "Add Ability File"
  def add_ability_file
    initializer "#{engine_name}_abilities_concern.rb" do
"require 'active_support/concern'

module #{engine_name.classify}AbilitiesConcern
  extend ActiveSupport::Concern
  included do
    def #{engine_name}_abilities user
      if user
        # if the user is logged in, it can do certain tasks regardless his role
        if user.admin?
          # if the user is an admin, it can do a lot of things, usually
        end

        if user.has_role? :role
          # a specific role, brings specific powers
        end
      end
    end
  end
end

# include the extension
TheCoreAbilities.send(:include, #{engine_name.classify}AbilitiesConcern)"
    end
  end

  desc "Add Gitignore"
  def manage_git
    in_root do
      if !File.exists?(Dir.pwd)
        append_file '.gitignore',".bundle/
log/*.log
pkg/
test/dummy/db/*.sqlite3
test/dummy/db/*.sqlite3-journal
test/dummy/log/*.log
test/dummy/tmp/
test/dummy/.sass-cache

# Created by https://www.gitignore.io/api/linux,osx,windows,linux,rails

### Linux ###
*~

# temporary files which can be created if a process still has a handle open of a deleted file
.fuse_hidden*

# KDE directory preferences
.directory

# Linux trash folder which might appear on any partition or disk
.Trash-*


### OSX ###
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two return
Icon


# Thumbnails
._*

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk


### Windows ###
# Windows image file caches
Thumbs.db
ehthumbs.db

# Folder config file
Desktop.ini

# Recycle Bin used on file shares
$RECYCLE.BIN/

# Windows Installer files
*.cab
*.msi
*.msm
*.msp

# Windows shortcuts
*.lnk


### Linux ###
*~

# temporary files which can be created if a process still has a handle open of a deleted file
.fuse_hidden*

# KDE directory preferences
.directory

# Linux trash folder which might appear on any partition or disk
.Trash-*


### Rails ###
*.rbc
capybara-*.html
.rspec
/log
/tmp
/db/*.sqlite3
/db/*.sqlite3-journal
/public/system
/coverage/
/spec/tmp
**.orig
rerun.txt
pickle-email-*.html

# TODO Comment out these rules if you are OK with secrets being uploaded to the repo
config/initializers/secret_token.rb
config/secrets.yml

## Environment normalization:
/.bundle
/vendor/bundle

# these should all be checked in to normalize the environment:
# Gemfile.lock, .ruby-version, .ruby-gemset

# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:
.rvmrc

# if using bower-rails ignore default bower_components path bower.json files
/vendor/assets/bower_components
*.bowerrc
bower.json

# Ignore pow environment settings
.powenv

# Ignore Byebug command history file.
.byebug_history

test/tmp
test/version_tmp
test/dummy/data
test/dummy/db/*.sqlite3
test/dummy/log/*
test/dummy/node_modules
test/dummy/public/assets
test/dummy/public/system
test/dummy/db/schema.rb
tmp
test/dummy/app/assets/javascripts/*.js
test/dummy/app/assets/javascripts/**/*.js
test/dummy/app/assets/javascripts/**/*.js.coffee
test/dummy/app/assets/javascripts/**/*.map
"
        git :init
        git add: ".gitignore"
        git commit: "-m 'Added Gitignore'"
        git add: "."
        git commit: "-m 'First commit'"
      end
      user = "#{@name}@" unless @name.blank?
      origin = "ssh://#{user}casatassoni.synology.me/volume1/git/rails/#{parent_name}/#{engine_name}.git"
      git remote: "set-url origin #{origin}"
    end
  end

  desc "Replace ActiveRecord::Base with ApplicationRecord"
  def replace_active_record
    dir = File.join("app", "models")
    # For each model in this gem
    inside dir do |dir_path|
      Dir.glob("*.rb").each { |entry|
        # It must be a class and don't have rails_admin declaration
        file = File.join(dir_path,entry)
        # say "Checking file #{file}", :red
        if is_activerecord?(file) && !has_rails_admin_declaration?(file)
          say "Replacing ActiveRecord::Base into #{entry}", :green
          # Add rails admin declaration
          gsub_file file, "ActiveRecord::Base", "ApplicationRecord"
        end
      }
    end
  end

  desc "Add rails_admin declaration only in files which are ActiveRecords and don't already have that declaration"
  def add_rails_admin_reference
    dir = File.join("app", "models")
    # For each model in this gem
    inside dir do |dir_path|
      Dir.glob("*.rb").each { |entry|
        # It must be a class and don't have rails_admin declaration
        file = File.join(dir_path,entry)
        # say "Checking file #{file}", :red
        if is_applicationrecord?(file) && !has_rails_admin_declaration?(file)
          say "Adding rails_admin to #{entry}", :green
          # Add rails admin declaration
          inject_into_file file, before: /^end/ do
"
  rails_admin do
    navigation_label I18n.t('admin.settings.label')
    navigation_icon 'fa fa-file'
  end
"
          end
        end
      }
    end
  end

  desc "Completes Belongs To Associations"
  def complete_belongs_to
    dir = File.join("app", "models")
    # For each model in this gem
    inside dir do |dir_path|
      Dir.glob("*.rb").each do |entry|
        # It must be a class and don't have rails_admin declaration
        file = File.join(dir_path,entry)
        # say "Checking file #{file}", :red
        if is_applicationrecord?(file)
          say "Adding inverse_of to all belongs_to in #{entry}", :green
          # belongs_to that don't have inverse_of
          gsub_file file, /^(?!.*inverse_of.*)^[ \t]*belongs_to.*$/ do |match|
            match << ", inverse_of: :#{entry.split(".").first.pluralize}"
          end
        end
      end
    end
  end

  desc "Add Has Many Associations"
  def add_has_many
  end

  desc "Add Has Many Through Associations"
  def add_has_many_through
  end

  private

  def is_activerecord? file
    File.readlines(file).grep(/^class [A-Za-z0-9]+ < ActiveRecord::Base/).size > 0
  end

  def is_applicationrecord? file
    File.readlines(file).grep(/^class [A-Za-z0-9]+ < ApplicationRecord/).size > 0
  end

  def has_rails_admin_declaration? file
    File.readlines(file).grep(/^[ \t]*rails_admin do/).size > 0
  end

  def is_engine? file
    File.readlines(file).grep(/^[ \t]*class Engine < ::Rails::Engine/).size > 0
  end

  def has_add_to_migrations_declaration? file
    File.readlines(file).grep(/^[ \t]*initializer '[a-zA-Z0-9]+\.add_to_migrations' do \|app\|/).size > 0
  end

  def engine_name
    inside @destination_stack.first do |path|
      return Dir.glob("*.gemspec").first.split(".").first
    end
  end

  def parent_name
    inside @destination_stack.first do |path|
      return File.expand_path("..", path).split(File::SEPARATOR).last
    end
  end
end
