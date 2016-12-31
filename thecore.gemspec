$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "thecore/version"

# Describe your s.add_dependency and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "thecore"
  s.version     = Thecore::VERSION
  s.authors     = ["Gabriele Tassoni"]
  s.email       = ["gabriele.tassoni@gmail.com"]
  s.homepage    = "http://thecore.it"
  s.summary     = "Core engine to be included in every application to provide base functionalities."
  s.description = "Start from here and build whatever you want to."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", '~> 5.0.0', '>= 5.0.0.1'
  # RICORDARSI DI FARE INCLUDE (in lib/thecore.rb) DI QUELLE GEMME CHE NE HANNO BISOGNO
  # s.add_dependency 'libv8', '~> 5.3', '>= 5.3.332.38'
  # TODO: remove when thor won't generate warnings anymore (problem appeared on 0.19.4)
  # s.add_dependency 'thor', '0.19.1'
  # -----------------------------------------------------------------------------------------------
  # PostgreSQL
  s.add_dependency 'pg', "~> 0.19"
  s.add_dependency 'seed_dump', "~> 3.2"
  # -----------------------------------------------------------------------------------------------
  # -----------------------------------------------------------------------------------------------
  # PAGINATION + GUI
  # Kaminari: https://github.com/amatsuda/kaminari
  s.add_dependency 'kaminari', "~> 0.17" #, '0.16.3'
  # Friendly_id: https://github.com/norman/friendly_id
  # s.add_dependency 'friendly_id' #, '5.1.0'
  # Font-awesome: https://github.com/FortAwesome/font-awesome-sass
  # Ricordarsi di usare il giusto asset precompile:
  # RAILS_ENV=production bundle exec rake assets:precompile RAILS_RELATIVE_URL_ROOT=/development/hiworkflows
  # Ovviamene se non sono in un suburi, allora non serve la parte relativa a RAILS_RELATIVE_URL_ROOT
  s.add_dependency 'font-awesome-sass', "~> 4.7" #, '~> 4.5.0'
  # Bootstrap 3: https://github.com/twbs/bootstrap-sass
  s.add_dependency 'bootstrap-sass', "~> 3.3" # , '3.3.5.1'
  # -----------------------------------------------------------------------------------------------
  # -----------------------------------------------------------------------------------------------
  # RAILS ADMIN
  # Devise: https://github.com/plataformatec/devise
  s.add_dependency 'devise', "~> 4.2" #, '4.0.1'
  s.add_dependency 'devise-i18n', "~> 1.1"
  s.add_dependency 'devise-i18n-views', "~> 0.3"
  s.add_dependency 'cancancan', "~> 1.15"
  s.add_dependency 'http_accept_language', "~> 2.1"
  # https://github.com/dalpo/rails_admin_clone
  #s.add_dependency 'rails_admin_clone'
  # Rails Admin
  s.add_dependency 'rails_admin_rollincode', '~> 1.1'
  s.add_dependency 'rails_admin', '~> 1.0'
  s.add_dependency 'rails_admin-i18n', "~> 1.11"
  #s.add_dependency 'rails_admin_history_rollback'
  s.add_dependency 'rails-i18n', "~> 5.0"
  # https://github.com/pgeraghty/rails_admin_charts
  # s.add_dependency 'rails_admin_charts'
  s.add_dependency 'rails_admin_toggleable', "~> 0.7"
  # s.add_dependency 'rails_admin_amoeba_dup'
  # OSX:
  # brew install imagemagick
  # brew install gs
  # Oppure (Debian):
  # sudo apt-get install imagemagick -y
  s.add_dependency "paperclip", "~> 5.0"
  # -----------------------------------------------------------------------------------------------
end
