require 'rails_admin'

require "thecore_actions"

include TheCoreActions

RailsAdmin.config do |config|
  #config.main_app_name = Proc.new {
  #  ["Hiworkflows", "(#{Time.zone.now.to_s(:time)})"]
  #}
  ### Popular gems integration

  ## == Devise ==
  config.authenticate_with do
    warden.authenticate! scope: :user
  end
  config.current_user_method(&:current_user)

  ## == Cancan ==
  config.authorize_with :cancan

  ## == PaperTrail ==
  # config.audit_with :paper_trail, 'User', 'PaperTrail::Version' # PaperTrail >= 3.0.0

  ### More at https://github.com/sferik/rails_admin/wiki/Base-configuration

  config.actions do
    # show_in_app
    dashboard # mandatory
    index # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    toggle
  end
end

# require "thecore_rails_admin_main_controller_concern"
