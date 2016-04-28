# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
# Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
#Rails.application.config.time_zone = 'Rome'

# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
#Rails.application.config.i18n.default_locale = :it
#I18n.enforce_available_locales = false

# Test framework
#Rails.application.config.generators.test_framework false

# autoload lib path
#Rails.application.config.autoload_paths += %W(#{Rails.application.config.root}/lib)

# Added to avoid flash error message: undefined method `flash' for #<ActionDispatch::Request
# That was caused by my api adding to a previosuly existing application
#Rails.application.config.api_only = false

# Include the authenticity token in remote forms.

# Rails.application.middleware.use ::ActionDispatch::Static, "#{root}/vendor"
