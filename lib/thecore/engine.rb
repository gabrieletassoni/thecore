module Thecore
  class Engine < ::Rails::Engine
    initializer "thecore.configure_rails_initialization", :group => :all do |app|
      # Engine configures Rails app here
      app.config.api_only = false
      # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
      # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
      app.config.time_zone = 'Rome'

      # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
      # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
      app.config.i18n.default_locale = :it

      # Assets
      app.config.assets.precompile += %w( thecore/ie.js )
      app.config.assets.precompile += %w( thecore/thecore.js )
      app.config.assets.precompile += %w( thecore/favicon.ico )
      app.config.assets.precompile += %w( thecore/apple-touch-icon.png )
      app.config.assets.precompile += %w( thecore/apple-touch-icon-precomposed.png )
      app.config.assets.precompile += %w( thecore/thecore.css )
      app.config.assets.precompile += %w( thecore/app_logo.png )
      app.config.assets.precompile += %w( thecore/main_app_logo.png )
    end

    # appending migrations to the main app's ones
    initializer "thecore.add_to_migrations" do |app|
      unless app.root.to_s == root.to_s
        # APPEND TO MAIN APP MIGRATIONS FROM THIS GEM
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
  end
end
