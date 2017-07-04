module Thecore
  class Engine < ::Rails::Engine
    initializer "thecore.configure_rails_initialization", group: :all do |app|
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
      app.config.assets.precompile += %w( thecore/thecore.css )
      app.config.assets.precompile += %w( thecore/app-logo.png )
      app.config.assets.precompile += %w( thecore/apple-touch-icon-ipad-76x76.png )
      app.config.assets.precompile += %w( thecore/apple-touch-icon-ipad-retina-152x152.png )
      app.config.assets.precompile += %w( thecore/apple-touch-icon-iphone-60x60.png )
      app.config.assets.precompile += %w( thecore/apple-touch-icon-iphone-retina-120x120.png )
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
