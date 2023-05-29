# Naming conventions

- _ATOMS_ and *gems* are interchangeable.
- `lib/[this_atom_name].rb` and similar, indicates the file, named after the current gem name, which resides in lib.
- `require '[other_atom]'` and similar, indicates the name of another gem on which the current one is dependant.

# ATOMS

## `*.gemspec` file

An _ATOM_ can depend on these two base thecore ATOMS. They can added together or just once, be the ATOM an API only gem or a gem which delivers functionalities useful for a GUI experience.

```ruby
s.add_dependency 'thecore_ui_rails_admin', '~> 3.0'
s.add_dependency 'model_driven_api', '~> 3.0'
```

The _ATOM_ can depend also on another _ATOM_, at which point `thecore_ui_rails_admin` and/or `model_driven_api` are already included in the dependency chain and only the other _ATOM_ needs to be added as a dependency.

### Autoload the dependency

It's advised to add in the `lib/[this_atom_name].rb` file all the **requires** pointing to depending _ATOMS_, for example, whenever you add a dependency in the `*.gemspec` file, please add the relevant `require '[other_atom]'` to the `lib/[this_atom_name].rb` of the current _ATOM_ you are developing.

## .gitignore

```ini
# Created by https://www.toptal.com/developers/gitignore/api/osx,macos,ruby,linux,rails,windows,sublimetext,visualstudio,visualstudiocode
# Edit at https://www.toptal.com/developers/gitignore?templates=osx,macos,ruby,linux,rails,windows,sublimetext,visualstudio,visualstudiocode

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

### macOS ###
# General
.DS_Store
.AppleDouble
.LSOverride

# Icon must end with two \r
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
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

### OSX ###
# General

# Icon must end with two \r

# Thumbnails

# Files that might appear in the root of a volume

# Directories potentially created on remote AFP share

### Rails ###
*.rbc
capybara-*.html
.rspec
/db/*.sqlite3
/db/*.sqlite3-journal
/db/*.sqlite3-[0-9]*
/public/system
/coverage/
/spec/tmp
*.orig
rerun.txt
pickle-email-*.html

# Ignore all logfiles and tempfiles.
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep

# TODO Comment out this rule if you are OK with secrets being uploaded to the repo
config/initializers/secret_token.rb
config/master.key

# Only include if you have production secrets in this file, which is no longer a Rails default
# config/secrets.yml

# dotenv, dotenv-rails
# TODO Comment out these rules if environment variables can be committed
.env
.env.*

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

# Ignore node_modules
node_modules/

# Ignore precompiled javascript packs
/public/packs
/public/packs-test
/public/assets

# Ignore yarn files
/yarn-error.log
yarn-debug.log*
.yarn-integrity

# Ignore uploaded files in development
/storage/*
!/storage/.keep

### Ruby ###
*.gem
/.config
/InstalledFiles
/pkg/
/spec/reports/
/spec/examples.txt
/test/tmp/
/test/version_tmp/
/tmp/

# Used by dotenv library to load environment variables.
# .env

# Ignore Byebug command history file.

## Specific to RubyMotion:
.dat*
.repl_history
build/
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
/.yardoc/
/_yardoc/
/doc/
/rdoc/

/.bundle/
/lib/bundler/man/

# for a library or gem, you might want to ignore these files since the code is
# intended to run in multiple environments; otherwise, check them in:
# Gemfile.lock
# .ruby-version
# .ruby-gemset

# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:

# Used by RuboCop. Remote config files pulled in from inherit_from directive.
# .rubocop-https?--*

### Ruby Patch ###
# Used by RuboCop. Remote config files pulled in from inherit_from directive.
# .rubocop-https?--*

### SublimeText ###
# Cache files for Sublime Text
*.tmlanguage.cache
*.tmPreferences.cache
*.stTheme.cache

# Workspace files are user-specific
*.sublime-workspace

# Project files should be checked into the repository, unless a significant
# proportion of contributors will probably not be using Sublime Text
# *.sublime-project

# SFTP configuration file
sftp-config.json

# Package control specific files
Package Control.last-run
Package Control.ca-list
Package Control.ca-bundle
Package Control.system-ca-bundle
Package Control.cache/
Package Control.ca-certs/
Package Control.merged-ca-bundle
Package Control.user-ca-bundle
oscrypto-ca-bundle.crt
bh_unicode_properties.cache

# Sublime-github package stores a github token in this file
# https://packagecontrol.io/packages/sublime-github
GitHub.sublime-settings

### VisualStudioCode ###
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
*.code-workspace

### VisualStudioCode Patch ###
# Ignore all local history of files
.history
.ionide

### Windows ###
# Windows thumbnail cache files
Thumbs.db
Thumbs.db:encryptable
ehthumbs.db
ehthumbs_vista.db

# Dump file
*.stackdump

# Folder config file
[Dd]esktop.ini

# Recycle Bin used on file shares
$RECYCLE.BIN/

# Windows Installer files
*.cab
*.msi
*.msix
*.msm
*.msp

# Windows shortcuts
*.lnk

### VisualStudio ###
## Ignore Visual Studio temporary files, build results, and
## files generated by popular Visual Studio add-ons.
##
## Get latest from https://github.com/github/gitignore/blob/master/VisualStudio.gitignore

# User-specific files
*.rsuser
*.suo
*.user
*.userosscache
*.sln.docstates

# User-specific files (MonoDevelop/Xamarin Studio)
*.userprefs

# Mono auto generated files
mono_crash.*

# Build results
[Dd]ebug/
[Dd]ebugPublic/
[Rr]elease/
[Rr]eleases/
x64/
x86/
[Aa][Rr][Mm]/
[Aa][Rr][Mm]64/
bld/
[Bb]in/
[Oo]bj/
[Ll]og/
[Ll]ogs/

# Visual Studio 2015/2017 cache/options directory
.vs/
# Uncomment if you have tasks that create the project's static files in wwwroot
#wwwroot/

# Visual Studio 2017 auto generated files
Generated\ Files/

# MSTest test Results
[Tt]est[Rr]esult*/
[Bb]uild[Ll]og.*

# NUnit
*.VisualState.xml
TestResult.xml
nunit-*.xml

# Build Results of an ATL Project
[Dd]ebugPS/
[Rr]eleasePS/
dlldata.c

# Benchmark Results
BenchmarkDotNet.Artifacts/

# .NET Core
project.lock.json
project.fragment.lock.json
artifacts/

# StyleCop
StyleCopReport.xml

# Files built by Visual Studio
*_i.c
*_p.c
*_h.h
*.ilk
*.meta
*.obj
*.iobj
*.pch
*.pdb
*.ipdb
*.pgc
*.pgd
*.rsp
*.sbr
*.tlb
*.tli
*.tlh
*.tmp
*.tmp_proj
*_wpftmp.csproj
*.log
*.vspscc
*.vssscc
.builds
*.pidb
*.svclog
*.scc

# Chutzpah Test files
_Chutzpah*

# Visual C++ cache files
ipch/
*.aps
*.ncb
*.opendb
*.opensdf
*.sdf
*.cachefile
*.VC.db
*.VC.VC.opendb

# Visual Studio profiler
*.psess
*.vsp
*.vspx
*.sap

# Visual Studio Trace Files
*.e2e

# TFS 2012 Local Workspace
$tf/

# Guidance Automation Toolkit
*.gpState

# ReSharper is a .NET coding add-in
_ReSharper*/
*.[Rr]e[Ss]harper
*.DotSettings.user

# TeamCity is a build add-in
_TeamCity*

# DotCover is a Code Coverage Tool
*.dotCover

# AxoCover is a Code Coverage Tool
.axoCover/*
!.axoCover/settings.json

# Coverlet is a free, cross platform Code Coverage Tool
coverage*[.json, .xml, .info]

# Visual Studio code coverage results
*.coverage
*.coveragexml

# NCrunch
_NCrunch_*
.*crunch*.local.xml
nCrunchTemp_*

# MightyMoose
*.mm.*
AutoTest.Net/

# Web workbench (sass)
.sass-cache/

# Installshield output folder
[Ee]xpress/

# DocProject is a documentation generator add-in
DocProject/buildhelp/
DocProject/Help/*.HxT
DocProject/Help/*.HxC
DocProject/Help/*.hhc
DocProject/Help/*.hhk
DocProject/Help/*.hhp
DocProject/Help/Html2
DocProject/Help/html

# Click-Once directory
publish/

# Publish Web Output
*.[Pp]ublish.xml
*.azurePubxml
# Note: Comment the next line if you want to checkin your web deploy settings,
# but database connection strings (with potential passwords) will be unencrypted
*.pubxml
*.publishproj

# Microsoft Azure Web App publish settings. Comment the next line if you want to
# checkin your Azure Web App publish settings, but sensitive information contained
# in these scripts will be unencrypted
PublishScripts/

# NuGet Packages
*.nupkg
# NuGet Symbol Packages
*.snupkg
# The packages folder can be ignored because of Package Restore
**/[Pp]ackages/*
# except build/, which is used as an MSBuild target.
!**/[Pp]ackages/build/
# Uncomment if necessary however generally it will be regenerated when needed
#!**/[Pp]ackages/repositories.config
# NuGet v3's project.json files produces more ignorable files
*.nuget.props
*.nuget.targets

# Microsoft Azure Build Output
csx/
*.build.csdef

# Microsoft Azure Emulator
ecf/
rcf/

# Windows Store app package directories and files
AppPackages/
BundleArtifacts/
Package.StoreAssociation.xml
_pkginfo.txt
*.appx
*.appxbundle
*.appxupload

# Visual Studio cache files
# files ending in .cache can be ignored
*.[Cc]ache
# but keep track of directories ending in .cache
!?*.[Cc]ache/

# Others
ClientBin/
~$*
*.dbmdl
*.dbproj.schemaview
*.jfm
*.pfx
*.publishsettings
orleans.codegen.cs

# Including strong name files can present a security risk
# (https://github.com/github/gitignore/pull/2483#issue-259490424)
#*.snk

# Since there are multiple workflows, uncomment next line to ignore bower_components
# (https://github.com/github/gitignore/pull/1529#issuecomment-104372622)
#bower_components/

# RIA/Silverlight projects
Generated_Code/

# Backup & report files from converting an old project file
# to a newer Visual Studio version. Backup files are not needed,
# because we have git ;-)
_UpgradeReport_Files/
Backup*/
UpgradeLog*.XML
UpgradeLog*.htm
ServiceFabricBackup/
*.rptproj.bak

# SQL Server files
*.mdf
*.ldf
*.ndf

# Business Intelligence projects
*.rdl.data
*.bim.layout
*.bim_*.settings
*.rptproj.rsuser
*- [Bb]ackup.rdl
*- [Bb]ackup ([0-9]).rdl
*- [Bb]ackup ([0-9][0-9]).rdl

# Microsoft Fakes
FakesAssemblies/

# GhostDoc plugin setting file
*.GhostDoc.xml

# Node.js Tools for Visual Studio
.ntvs_analysis.dat

# Visual Studio 6 build log
*.plg

# Visual Studio 6 workspace options file
*.opt

# Visual Studio 6 auto-generated workspace file (contains which files were open etc.)
*.vbw

# Visual Studio LightSwitch build output
**/*.HTMLClient/GeneratedArtifacts
**/*.DesktopClient/GeneratedArtifacts
**/*.DesktopClient/ModelManifest.xml
**/*.Server/GeneratedArtifacts
**/*.Server/ModelManifest.xml
_Pvt_Extensions

# Paket dependency manager
.paket/paket.exe
paket-files/

# FAKE - F# Make
.fake/

# CodeRush personal settings
.cr/personal

# Python Tools for Visual Studio (PTVS)
__pycache__/
*.pyc

# Cake - Uncomment if you are using it
# tools/**
# !tools/packages.config

# Tabs Studio
*.tss

# Telerik's JustMock configuration file
*.jmconfig

# BizTalk build output
*.btp.cs
*.btm.cs
*.odx.cs
*.xsd.cs

# OpenCover UI analysis results
OpenCover/

# Azure Stream Analytics local run output
ASALocalRun/

# MSBuild Binary and Structured Log
*.binlog

# NVidia Nsight GPU debugger configuration file
*.nvuser

# MFractors (Xamarin productivity tool) working folder
.mfractor/

# Local History for Visual Studio
.localhistory/

# BeatPulse healthcheck temp database
healthchecksdb

# Backup folder for Package Reference Convert tool in Visual Studio 2017
MigrationBackup/

# Ionide (cross platform F# VS Code tools) working folder
.ionide/

# End of https://www.toptal.com/developers/gitignore/api/osx,macos,ruby,linux,rails,windows,sublimetext,visualstudio,visualstudiocode
```

## Root Actions

Root Actions are [Rails Admin](https://github.com/railsadminteam/rails_admin) actions which are not directly dependant on a Model. They don't follow CRUD and add a business logic level to the application, in order to provide a more complex interaction witht he User.
The menu entry will be rentered in a special section of the menu, outside Model's ones.

They are defined by convention in the `lib/root_actions` folder of the gem and follow a specific format, like this example from the [Thecore TCP Debug]() _ATOM_.

Have a look at the comments in this snippet to bettr understand:

```ruby
RailsAdmin::Config::Actions.add_action "tcp_debug", :base, :root do
    # For the root action's menu item to appear in the right menu, these five ones are mandatory:
    show_in_sidebar true
    show_in_navigation false
    breadcrumb_parent [nil]
    member false
    collection false
    
    # Icon is the graphical element whch appears besides the menu item, must be chosen from 
    # FontAwesome available icons:
    link_icon 'fas fa-heartbeat'
    
    # The method to interact with the controller section below, can be any HTTP verb, also more than one
    http_methods [:get]

    # Adding the controller which is needed to compute calls from the ui
    controller do
        # This is needed because we need that this code is re-evaluated each time is called
        # this mins the proc do part is mandatory
        proc do
            # Not mandatory, but is always useful to distinguish between a REST or an AJAX call.
            if request.xhr?
                # I can access params passed during the call and use them inside this controller's business logic.
                case params["test"]
                when "telnet"
                    port_is_open = Socket.tcp(params["host"], params["port"], connect_timeout: 5) { true } rescue false
                    message, status = { debug_status: I18n.t("tcp_debug_telnet_ko", host: params["host"].presence || "-", port: params["port"].presence || "-") }, 503
                    message, status = { debug_status: I18n.t("tcp_debug_telnet_ok", host: params["host"].presence || "-", port: params["port"].presence || "-") }, 200 if port_is_open
                when "ping"
                    check = Net::Ping::External.new(params["host"])
                    message, status = { debug_status: I18n.t("tcp_debug_ping_ko", host: params["host"].presence || "-") }, 503
                    message, status = { debug_status: I18n.t("tcp_debug_ping_ok", host: params["host"].presence || "-") }, 200 if check.ping?
                else
                    message, status = { debug_status: I18n.t("invalid_test", host: params["host"]) }, 400
                end

                # Thecore comes preconfigured to deliver Websocket messages, why not use them to make this 
                # controller more reactive?
                ActionCable.server.broadcast("messages", { topic: :tcp_debug, status: status, message: message})

                # It follows the RESTful convention:
                render json: message.to_json, status: status
            else
                Rails.logger.debug "When the request is not an AJAX call."
            end
        end
    end
end
```

### Load the root action at runtime

In `config/initializers/after_initialize.rb` add the require to load this root action, like: `require "root_actions/tcp_debug"`.

### The View

In `app/views/rails_admin/main/tcp_debug.html.erb` add the HTML that must be rendered to create the UX.

### Styles

Add all the styles that are only needed in the current **Root Action** in a  file named after the action name defined in `RailsAdmin::Config::Actions.add_action`, in this example the right place is: `app/assets/stylesheets/main_tcp_debug.scss`.
Please note that the controller is always main in Rails Admin context and the other part is the root action name.

### Javascripts

Javascript can be added in two different ways, be it conventionally loadaded in the layout using the controller and action names or embedded in a `<script></script>` tag directly in the `*.html.erb` file.
Both need to follow some guidelines to be correctly loaded at runtime by both Turbo or a normal RESTful call of the page.

#### Based on the Action Name

Add all the jvascripts that are only needed in the current **Root Action** in a  file named after the action name defined in `RailsAdmin::Config::Actions.add_action`, in this example the right place is: `app/assets/stylesheets/main_tcp_debug.js`.
Please note that the controller is always main in Rails Admin context and the other part is the root action name.

#### Embedded in HTML.ERB files

To embed the Javascript file directly into the action's `.html.erb` file is advised to:

- Surround the code in a `<script></script>` tag.
- Put all the variables needed by the events in the root of the script tag.
- Put all the functions at the root of the script tag.
- Put all the business logic into a `document.addEventListener("turbo:load", function (event) { });` listener.

# THECORE APP

## Dependencies

In the thecore APP the preferred way to integrate your code is by putting in the Gemfile.base the ATOM which depends on the base thecore ATOMS: [Model Driven API](https://github.com/gabrieletassoni/model_driven_api) and [Thecore UI Rails Admin](https://github.com/gabrieletassoni/thecore_ui_rails_admin). These are added in a separate way to allow developer to focus on the needed aspects of the application, UI or API based.

```ruby
gem 'your_business_logic_atom', '~> 3.0'
```
