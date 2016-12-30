class ThecorizePluginGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  # Something like:
  #
  class_option :git_server, aliases: "-g"

  def init_constants
    @plugin_path = @destination_stack.first.match(Regexp.new("^.*#{@name}"))[0]
    @parent_path = File.expand_path("..", @plugin_path)
    inside @plugin_path do
      @plugin_parent_name = @parent_path.split(File::SEPARATOR).last
      @plugin_initializers_dir = File.join(@plugin_path, "config", "initializers")
      @plugin_models_dir = File.join(@plugin_path, "app", "models")
      @plugin_lib_file = File.join(@plugin_path, "lib", @name, "engine.rb")
      Dir.chdir @plugin_models_dir do
        # Getting all the models that are activerecords:
        @model_files = Dir.glob("*.rb").map do |model|
          file = File.join(@plugin_models_dir,model)
          model if is_applicationrecord?(file)
        end.compact
      end
    end
  end

  desc "Make migrations usable into main app"
  def migrations_to_main_app
    if is_engine?(@plugin_lib_file) && !has_add_to_migrations_declaration?(@plugin_lib_file)
      # say "Adding migration reflection into engine.rb of #{@name}", :green
      inject_into_file @plugin_lib_file, after: "class Engine < ::Rails::Engine\n" do
"
    initializer '#{@name}.add_to_migrations' do |app|
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

  desc "Add Ability File"
  def add_ability_file
    # do this just the first time
    abilities_file_name = "abilities_#{@name}_concern.rb"
    abilities_file_fullpath = File.join(@plugin_initializers_dir, abilities_file_name)
    initializer abilities_file_name do
"require 'active_support/concern'

module #{@name.classify}AbilitiesConcern
  extend ActiveSupport::Concern
  included do
    def #{@name}_abilities user
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
TheCoreAbilities.send(:include, #{@name.classify}AbilitiesConcern)"
    end unless File.exists?(abilities_file_fullpath)
  end

  desc "Add Gitignore"
  def manage_git
    inside @plugin_path do
      if !File.exists?(File.join(@plugin_path, '.git'))
        remove_file File.join(@plugin_path, '.gitignore') if File.exists?(File.join(@plugin_path, '.gitignore'))
        create_file File.join(@plugin_path, '.gitignore'),".bundle/
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
      unless options[:git_server].blank?
        origin = URI.join(options[:git_server], @plugin_parent_name, "#{@name.git}")
        git remote: "set-url origin #{origin}"
      end
    end
  end

  desc "Replace ActiveRecord::Base with ApplicationRecord"
  def replace_active_record
    # For each model in this gem
    inside @plugin_models_dir do
      Dir.glob("*.rb").each { |entry|
        # It must be a class and don't have rails_admin declaration
        file = File.join(@plugin_models_dir,entry)
        # say "Checking file #{file}", :red
        if is_activerecord?(file) && !has_rails_admin_declaration?(file)
          # say "Replacing ActiveRecord::Base into #{entry}", :green
          # Add rails admin declaration
          gsub_file file, "ActiveRecord::Base", "ApplicationRecord"
        end
      }
    end
  end

  desc "Add rails_admin declaration only in files which are ActiveRecords and don't already have that declaration"
  def add_rails_admin_reference
    # For each model in this gem
    inside @plugin_models_dir do
      Dir.glob("*.rb").each { |entry|
        # It must be a class and don't have rails_admin declaration
        file = File.join(@plugin_models_dir,entry)
        # say "Checking file #{file}", :red
        if is_applicationrecord?(file) && !has_rails_admin_declaration?(file)
          # say "Adding rails_admin to #{entry}", :green
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
    # For each model in this gem
    inside @plugin_models_dir do
      Dir.glob("*.rb").each do |entry|
        # It must be a class and don't have rails_admin declaration
        file = File.join(@plugin_models_dir,entry)
        # say "Checking file #{file}", :red
        if is_applicationrecord?(file)
          # say "Adding inverse_of to all belongs_to in #{entry}", :green
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
    # For each model in this gem
    inside @plugin_models_dir do
      Dir.glob("*.rb").each do |entry|
        file = File.join(@plugin_models_dir,entry)
        # It must be an activerecord model class
        if is_applicationrecord?(file)
          # say "Looking for belongs_to in #{entry} and adding the relevant has_manies", :green

          # Polymorphic must be managed manually
          File.readlines(file).grep(/^(?!.*polymorphic.*)^[ \t]*belongs_to :(.*),.+/).each do |a|
            target_association = a[/:(.*?),/,1]
            # look if the file identified by association .rb exists
            associated_file = File.join(@plugin_models_dir,"#{target_association}.rb")
            starting_model = entry.split(".").first.pluralize
            # say "Found belongs_to association: #{target_association} for the model: #{starting_model}", :green
            # say "- Looking for model file: #{associated_file}", :green
            if File.exists?(associated_file)
              # say "The file in which to add has_many, exists and the has_many does not! #{associated_file}", :green
              # if true, check that the association is non existent and add the association to that file
              inject_into_file associated_file, after: " < ApplicationRecord\n" do
"  has_many :#{starting_model}, inverse_of: :#{target_association}, dependent: :destroy
"
              end unless has_has_many_association?(associated_file, starting_model)
            else
              # otherwise (the file does not exist) check if the initializer for concerns exists,
              # For each model in this gem
              inside @plugin_path do
                initializer_name = "associations_#{target_association}_concern.rb"
                initializer initializer_name do
"require 'active_support/concern'

module #{target_association.classify}AssociationsConcern
  extend ActiveSupport::Concern
  included do
  end
end

# include the extension
#{target_association.classify}.send(:include, #{target_association.classify}AssociationsConcern)
"
                end unless File.exists?(File.join(@plugin_initializers_dir, initializer_name))

                # then add to it the has_many declaration
                # TODO: only if it doesn't already exists
                inject_into_file File.join(@plugin_initializers_dir, initializer_name), after: "included do\n" do
"    has_many :#{starting_model}, inverse_of: :#{target_association}, dependent: :destroy
"
                end
              end
            end
          end
        end
      end
    end
  end

  desc "Add Has Many Through Associations"
  def add_has_many_through
  end

  desc "Detect polymorphic Associations"
  def detect_polymorphic_associations
    # For each model in this gem
    # say "MODEL FILES: #{@model_files.inspect} "
    @model_files.each do |model|
      file = File.join(@plugin_models_dir,model)
      # It must be an activerecord model class
      # belongs_to :rowable, polymorphic: true, inverse_of: :rows
      polymorphics = File.readlines(file).grep(/^[ \t]*belongs_to :.*polymorphic.*/)
      say "Find all Polymorphic Associations, these must be handled manually:" unless polymorphics.empty?
      polymorphics.each do |polymorphic_belongs_to|
        polymorphic_target_association = polymorphic_belongs_to[/:(.*?),/,1]
        say " - Polymorphic belongs_to (#{polymorphic_target_association}) found in #{model}", :red
        # Just keeping the models that are not this model, and
        answers = ask_question_multiple_choice @model_files.reject {|m| m == model && !has_polymorphic_has_many?(File.join(@plugin_models_dir,m), polymorphic_target_association)}, " - - Where do you want to add the polymorphic has_many?"
        answers.each do |answer|
          # Add the polymorphic has_name declaration
          inject_into_file File.join(@plugin_models_dir, answer), after: " < ApplicationRecord\n" do
"  has_many :#{model.split(".").first.pluralize}, as: :#{polymorphic_target_association}, inverse_of: :#{answer.split(".").first.singularize}, dependent: :destroy
"
          end
        end
      end
    end
  end

  private

  def ask_question_multiple_choice models, question = "Choose among one of these, please."
    return [] if models.empty?
    # raccolgo tutte le risposte che non siano cancel
    # e ritorno l'array
    return_array = []
    while (answer ||= "") != "cancel"
      remaining_models = (models-return_array)
      break if remaining_models.empty?
      answer = ask question, limited_to: remaining_models.push("cancel").uniq
      break if answer == "cancel"
      return_array.push answer
    end
    return return_array
  end

  def has_polymorphic_has_many? file, polymorphic_name
    (File.readlines(file).grep(/^[ \t]*has_many.+as: :#{polymorphic_name}.*/).size > 0) rescue false
  end

  def is_activerecord? file
    (File.readlines(file).grep(/^class [A-Za-z0-9]+ < ActiveRecord::Base/).size > 0) rescue false
  end

  def is_applicationrecord? file
    (File.readlines(file).grep(/^class [A-Za-z0-9]+ < ApplicationRecord/).size > 0) rescue false
  end

  def has_rails_admin_declaration? file
    (File.readlines(file).grep(/^[ \t]*rails_admin do/).size > 0) rescue false
  end

  def is_engine? file
    (File.readlines(file).grep(/^[ \t]*class Engine < ::Rails::Engine/).size > 0) rescue false
  end

  def has_add_to_migrations_declaration? file
    (File.readlines(file).grep(/^[ \t]*initializer '[a-zA-Z0-9]+\.add_to_migrations' do \|app\|/).size > 0) rescue false
  end

  def has_has_many_association? file, assoc
    reg_def = "^[ \\t]+has_many[ \\t]+:#{assoc}"
    (File.readlines(file).grep(Regexp.new(reg_def)).size > 0) rescue false
  end
end
