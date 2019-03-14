require 'rails'
require 'rails/application'
require 'application_record_loader'
require 'thecore_base_roles'
require 'active_record_extension'
require 'integer_extensions'
require 'string_extensions'
require 'activerecord_paperclip_extension'
require 'abilities'
require 'application_configs'
require 'backtrace_silencers'
require 'constants'
require 'date_format'
require 'inflections'
require 'mime_types'
require 'postgresql_drop_replacement'

require 'rails_admin_rollincode'
require 'rails_admin'
require 'rails_admin_toggleable'
require 'rails_admin-i18n'
require "wysiwyg-rails"
require 'serviceworker-rails'

require 'rails-i18n'
require 'kaminari'
require 'kaminari_config'
require 'devise'
require 'devise_initializer'
require 'devise-i18n'
require 'cancancan'
require 'http_accept_language'
require 'bootstrap-sass'
require 'font-awesome-sass'

require 'thecore_rails_admin_export_concern'
require 'thecore_rails_admin_bulk_delete_concern'

require 'oj'
require 'multi_json'
require 'date_validator'
require 'ckeditor'
require "ckeditor/orm/active_record"

require "webpacker"

require 'thecore/engine'

module Thecore
end
