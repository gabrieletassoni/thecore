Rails.application.configure do
  config.assets.precompile += %w( favicon.ico )
  config.assets.precompile += %w( apple-touch-icon.png )
  config.assets.precompile += %w( favicon-32x32.png )
  config.assets.precompile += %w( favicon-16x16.png )
  config.assets.precompile += %w( safari-pinned-tab.svg )
  config.assets.precompile += %w( mstile-150x150.svg )
  config.assets.precompile += %w( android-chrome-192x192.png )
  config.assets.precompile += %w( android-chrome-512x512.png )
  config.assets.precompile += %w( logo.png )
  config.assets.precompile += %w( up-arrow.png )
  # mstile-150x150
  config.assets.precompile += %w( thecore.js )
  config.assets.precompile += %w( thecore.css )
  # config.assets.precompile += %w( app_logo.png )
  # config.assets.precompile += %w( main_app_logo.png )
  config.assets.precompile += %w( ie.js )
  config.assets.precompile += %w( manifest.json )
  config.assets.precompile += %w( browserconfig.xml )

  config.filter_parameters += [:password]

  config.active_record.raise_in_transactional_callbacks = true

  config.serviceworker.routes.draw do
    match "/manifest.json"
  end
end
