require 'rails_admin'

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
    dashboard                   # mandatory
    index                         # mandatory
    new do
      except ['ChosenDeck', 'ChosenRoom']
    end
    export
    bulk_delete
    show do
      except ['PrintJob']
    end
    clone do
      except ['PrintJob']
    end
    edit
    delete
    # show_in_app
    telnet_print do
      only ['Commission', 'Bundle']
    end
    list_associated_items do
      only ['Commission', 'Bundle']
    end
    ## With an audit adapter, you can add:
    # history_index
    # history_show
  end

  # config.model 'User' do
  #
  # end
end
