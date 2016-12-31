class ThecorizeAppGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def setup_variables
    @plugin_path = @destination_stack.first.match(Regexp.new("^.*#{@name}"))[0]
    @plugin_parent_name = @parent_path.split(File::SEPARATOR).last
  end

  desc "Add Gitignore"
  def manage_git
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

      inside @plugin_path do
        git :init
        git add: ".gitignore"
        git commit: "-m 'Added Gitignore'"
        git add: "."
        git commit: "-m 'First commit'"
      end
    end
    unless options[:git_server].blank?
      origin = URI.join(options[:git_server], @plugin_parent_name, "#{@name.git}")
      git remote: "set-url origin #{origin}"
    end
  end
end
