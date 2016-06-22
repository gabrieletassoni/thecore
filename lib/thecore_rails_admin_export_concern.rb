require 'active_support/concern'

module ExportConcern
  extend ActiveSupport::Concern
  included do
    # Should the action be visible
    # Edit By taris, it shows the button only if there are records displayed
    register_instance_option :visible? do
      # If not in index, then return true,
      # otherwise it wont' be added to the list
      # of all Actions during rails initialization
      # In index, instead, I show it only if there are records in the current view
      bindings[:controller].action_name == "index" ? (authorized? && !bindings[:controller].instance_variable_get("@objects").blank?) : true
    end
  end
end

# include the extension
RailsAdmin::Config::Actions::Export.send(:include, ExportConcern)
