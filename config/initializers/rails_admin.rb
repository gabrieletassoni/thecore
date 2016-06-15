require 'rails_admin'

require "thecore_actions"

# TODO: Documentare bene per sapere quali file mettere nel caso di custom actions
# Carica tutti i file ruby che finiscono con _actions.rb, qui ci sono le configurazioni automatiche
# dei plugin di rails admin
# require 'logger'
# Dir["./../../../../**/config/initializers/*_actions.rb"].each do |f|
#   Rails.logger.info "LOADING FILES: #{f}"
#   begin
#     require f
#   rescue
#     Rails.logger.info "Cannot Load, maybe not added to gemfile."
#   end
# end

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
    # clone
    edit
    delete
    toggle
    # TheCoreActions.instance_methods(false).each do |a|
    #   # method(a).call(user)
    #   # eval("#{a} #{user}")
    #   Rails.logger.info "LOADING ACTION FROM: #{a}"
    #   begin
    #     send(a)
    #   rescue
    #     Rails.logger.info "Cannot Load, maybe not added to gemfile."
    #   end
    # end
    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end
end
