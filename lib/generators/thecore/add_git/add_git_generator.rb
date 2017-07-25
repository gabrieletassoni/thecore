require 'rails/generators/named_base'
module Thecore
  class AddGitGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    # TODO: add a .gitignore good for Rails and manage git
    # "Traversing the DIR structures it adds git remote URL", "By checking wether or not the .git folder exists, it inits or changes the url."
    def update_or_init_git_remote
      create_file '.gitignore', "

# Created by https://www.gitignore.io/api/linux,osx,windows,rails,ruby,rubymine
### Linux ###
*~
# temporary files which can be created if a process still has a handle open of a deleted file
.fuse_hidden*
# KDE directory preferences
.directory
# Linux trash folder which might appear on any partition or disk
.Trash-*
# .nfs files are created when an open file is removed but is still being accessed
.nfs*
### OSX ###
*.DS_Store
.AppleDouble
.LSOverride
# Icon must end with two \r
Icon\r\r

# Thumbnails
._*
# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent
# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk
### Windows ###
# Windows thumbnail cache files
Thumbs.db
ehthumbs.db
ehthumbs_vista.db
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
### Rails ###
/test/dummy/log
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
# TODO Comment out this rule if you are OK with secrets being uploaded to the repo
config/initializers/secret_token.rb
# Only include if you have production secrets in this file, which is no longer a Rails default
# config/secrets.yml
# dotenv
# TODO Comment out this rule if environment variables can be committed
.env
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
# Ignore bundler config
/vendor/bundle/
/vendor/ruby/
# Ignore the default database.
/db/*.javadb/
# Ignore all logfiles and tempfiles.
/log/*
.powder
.virb*
*.*~
# various artifacts
**.war
*.gem
*.sassc
.redcar/
.config
.sass-cache
/public/cache
/public/stylesheets/compiled
/public/system/*
/public/assets/*
/public/sitemaps
/spec/tmp/*
/cache
/capybara*
/capybara-*.html
/gems
/specifications
.zeus.sock
/solr/
/.gemtags
/coverage
/coverage.data
/InstalledFiles
/pkg/
/spec/reports/
/test/tmp/
/test/version_tmp/
# scm revert files
# Configuration files
config/app_config.yml
config/database.yml
config/application.yml
config/mandrill.yml
config/paperclip.yml
# System Recordings from Tropo
public/tropo_recordings/**/*
public/system/**/*
# Dev Machines
.DS_Store
*/.DS_Store
Procfile.dev
.env.development
.env.test
.env.staging
.env.production
/*.sublime-workspace
# Netbeans project directory
/nbproject/
# RubyMine project files
.idea
# Textmate project files
/*.tmproj
# vim artifacts
**.swp
.vim
/.tags
/.tags_sorted_by_file
# Application specific
*.txt
/doc
/public/uploads
# Specific to RubyMotion:
.dat*
.repl_history
build/
# Documentation cache and generated files:
/.yardoc/
/_yardoc/
/rdoc/
# Environment normalisation:
/.bundle/
/lib/bundler/man/
# for a library or gem, you might want to ignore these files since the code is
# intended to run in multiple environments; otherwise, check them in:
Gemfile.lock
# .ruby-version
# .ruby-gemset
.DS_store
# Windows image file caches
### Ruby ###
/.config
/spec/examples.txt
/tmp/
# Used by dotenv library to load environment variables.
# .env
## Specific to RubyMotion:
*.bridgesupport
build-iPhoneOS/
build-iPhoneSimulator/
## Specific to RubyMotion (use of CocoaPods):
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
# vendor/Pods/
## Documentation cache and generated files:
/doc/
### RubyMine ###
# Covers JetBrains IDEs: IntelliJ, RubyMine, PhpStorm, AppCode, PyCharm, CLion, Android Studio and Webstorm
# Reference: https://intellij-support.jetbrains.com/hc/en-us/articles/206544839
# User-specific stuff:
.idea/workspace.xml
.idea/tasks.xml
# Sensitive or high-churn files:
.idea/dataSources/
.idea/dataSources.ids
.idea/dataSources.xml
.idea/dataSources.local.xml
.idea/sqlDataSources.xml
.idea/dynamic.xml
.idea/uiDesigner.xml
# Gradle:
.idea/gradle.xml
.idea/libraries
# Mongo Explorer plugin:
.idea/mongoSettings.xml
## File-based project format:
*.iws
## Plugin-specific files:
# IntelliJ
/out/
# mpeltonen/sbt-idea plugin
.idea_modules/
# JIRA plugin
atlassian-ide-plugin.xml
# Crashlytics plugin (for Android Studio and IntelliJ)
com_crashlytics_export_strings.xml
crashlytics.properties
crashlytics-build.properties
fabric.properties
### RubyMine Patch ###
# Comment Reason: https://github.com/joeblau/gitignore.io/issues/186#issuecomment-215987721
# *.iml
# modules.xml
# .idea/misc.xml
# *.ipr
# End of https://www.gitignore.io/api/linux,osx,windows,rails,ruby,rubymine

"
      git :init
      git add: ".gitignore"
      git commit: "-a -m 'Added gitignore'"
      git add: ". -A"
      git commit: "-a -m 'First commit'"
      Dir.chdir(".git/hooks") do
        File.rename("post-update.sample", "post-update") rescue nil
        system "chmod +x post-update"
      end
      project_dir = File.basename File.expand_path("..", Dir.pwd)
      engine_dir = File.basename File.expand_path(".", Dir.pwd)
      remote_url = `"git config --get remote.origin.url"`
      action = remote_url.empty? ? "add" : "set-url"
      system "git remote #{action} origin https://www.taris.it/git/rails/#{project_dir}/#{engine_dir}.git"
      system "git update-server-info"
      Dir.chdir("..") do
        system "git clone --bare #{engine_dir} #{engine_dir}.git"
      end
    end
  end
end
