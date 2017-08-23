require 'active_support/concern'

module ThecoreConcern
  extend ActiveSupport::Concern

  included do
    # Prevent CSRF attacks by raising an exception.
    # For APIs, you may want to use :null_session instead.
    layout 'thecore'
    protect_from_forgery with: :exception, prepend: true
    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, :alert => exception.message
    end
    include HttpAcceptLanguage::AutoLocale
    Rails.logger.debug "Selected Locale: #{I18n.locale}"
    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :reject_locked!, if: :devise_controller?

    helper_method :reject_locked!
    helper_method :require_admin!
    helper_method :line_break
    helper_method :title
    helper_method :bootstrap_class_for

    # Redirects on successful sign in
    def after_sign_in_path_for resource
      Rails.logger.debug("SUCCESFULL SIGNIN, USER IS ADMIN? #{current_user.admin?}")
      #if current_user.admin?
      # GETTING JUST THE ROOT ACTIONS I (CURRENT_USER) CAN MANAGE
      root_actions = RailsAdmin::Config::Actions.all(:root).select {|action| can? action.action_name, :all }
      # Rails.logger.debug "ROOT ACTIONS: #{root_actions.inspect}"
      # GETTING THE FIRST ACTION I CAN MANAGE
      action = root_actions.collect(&:action_name).first
      # Rails.logger.debug "FIRST ACTION: #{action}"
      # REDIRECT TO THAT ACTION
      rails_admin.send("#{action}_path").sub("#{ENV['RAILS_RELATIVE_URL_ROOT']}#{ENV['RAILS_RELATIVE_URL_ROOT']}", "#{ENV['RAILS_RELATIVE_URL_ROOT']}")
      #rails_admin.dashboard_path.sub("#{ENV['RAILS_RELATIVE_URL_ROOT']}#{ENV['RAILS_RELATIVE_URL_ROOT']}", "#{ENV['RAILS_RELATIVE_URL_ROOT']}")
      #elsif current_user.has_role? :workers
      #  rails_admin.new_path('timetable').sub("#{ENV['RAILS_RELATIVE_URL_ROOT']}#{ENV['RAILS_RELATIVE_URL_ROOT']}", "#{ENV['RAILS_RELATIVE_URL_ROOT']}")
      #else
      #  inside_path
      #end
    end
  end

  def title value = "Thecore"
    @title = value
  end

  def bootstrap_class_for flash_type
    case flash_type
    when 'success'
      'alert-success'
    when 'error'
      'alert-danger'
    when 'alert'
      'alert-warning'
    when 'notice'
      'alert-info'
    else
      flash_type.to_s
    end
  end

  def line_break s
    s.gsub("\n", "<br/>")
  end
  # Devise permitted params
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(
      :username,
      :password,
      :password_confirmation,
      :remember_me)
    }
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(
      :username,
      :password,
      :password_confirmation)
    }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(
      :username,
      :password,
      :password_confirmation,
      :current_password
      )
    }
  end

  # Auto-sign out locked users
  def reject_locked!
    if current_user && current_user.locked?
      sign_out current_user
      user_session = nil
      current_user = nil
      flash[:alert] = "Your account is locked."
      flash[:notice] = nil
      redirect_to root_url
    end
  end

  # Only permits admin users
  def require_admin!
    authenticate_user!

    if current_user && !current_user.admin?
      redirect_to inside_path
    end
  end
end

# include the extension
ActionController::Base.send(:include, ThecoreConcern)
