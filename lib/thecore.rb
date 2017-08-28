require 'rails'
require 'rails/application'
require 'application_record_loader'
require 'thecore_base_roles'
require 'active_record_extension'
require 'integer_extensions'
require 'activerecord_paperclip_extension'
require 'abilities'
require 'application_configs'
require 'backtrace_silencers'
require 'constants'
require 'date_format'
require 'inflections'
require 'mime_types'
require 'postgresql_drop_replacement'

# require 'rails_admin_clone'
require 'rails_admin_rollincode'
require 'rails_admin'
require 'rails_admin_toggleable'
require 'rails_admin-i18n'
# require 'rails_admin_initializer'
# require 'rails_admin_history_rollback'
require 'serviceworker-rails'

require 'rails-i18n'
require 'kaminari'
require 'kaminari_config'
require 'devise'
require 'devise_initializer'
# require 'rails_admin_amoeba_dup'
require 'devise-i18n'
require 'devise-i18n-views'
require 'cancancan'
require 'http_accept_language'
require 'bootstrap-sass'
require 'font-awesome-sass'
# require 'friendly_id'
require 'paperclip'

require 'thecore_rails_admin_export_concern'
require 'thecore_rails_admin_bulk_delete_concern'

require 'thecore/engine'

# require 'controllers/application_controller'
# require 'controllers/pages_controller'
#
# require 'jobs/application_job'
#
# require 'models/ability'
# require 'models/application_record'
# require 'models/user'
#
# require 'uploaders/attachment_uploader'
# require 'uploaders/image_uploader'

module Thecore
end
