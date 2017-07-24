Rails.application.configure do
  config.assets.precompile += %w( favicon.ico )
  config.assets.precompile += %w( apple-touch-icon.png )
  config.assets.precompile += %w( thecore.js )
  config.assets.precompile += %w( thecore.css )
  config.assets.precompile += %w( app_logo.png )
  config.assets.precompile += %w( main_app_logo.png )
  config.assets.precompile += %w( ie.js )

  config.filter_parameters += [:password]

  config.active_record.raise_in_transactional_callbacks = true
end
