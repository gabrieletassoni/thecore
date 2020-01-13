class User < ApplicationRecord
  include RailsAdmin
  # # include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable, :timeoutable, timeout_in: 30.minutes

  before_create :generate_authentication_token

  paginates_per 50

  # Validations
  # :username
  validates :username, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /\A[a-zA-Z0-9]*\z/, on: :create, message: "can only contain letters and digits"
  validates :username, length: { in: 4..15 }
  # :email
  validates :email, uniqueness: { case_sensitive: false }
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

  validates :username, presence: true
  validates :email, presence: true

  validates :password, presence: true, on: :create
  validates :password_confirmation, presence: true, on: :create

  validates :roles, presence: true, on: :create, :unless => lambda { ROLES.blank? }

  def self.paged(page_number)
    order(admin: :desc, username: :asc).page page_number
  end

  def self.search_and_order(search, page_number)
    if search
      where("username LIKE ?", "%#{search.downcase}%").order(
      admin: :desc, username: :asc
      ).page page_number
    else
      order(admin: :desc, username: :asc).page page_number
    end
  end

  def self.last_signups(count)
    order(created_at: :desc).limit(count).select("id","username","created_at")
  end

  def self.last_signins(count)
    order(last_sign_in_at:
    :desc).limit(count).select("id","username","last_sign_in_at")
  end

  def self.users_count
    where(admin: false, locked: false).count
  end
  
  def timeout_in
    return 30.minutes if admin?
    1.day
  end
  
  def title
    username
  end

  # serialize :roles, Array if Settings.single_role_per_user == "f"
  def roles_enum
    # Do not EDIT below this line
    ROLES.each_with_index.map {|a,i| [I18n.t("roles.#{a.to_sym}"), (i+1).to_s]}
  end
  def has_role? role
    # example called from cancan's app/models/ability.rb
    # if user.has_role? :admin

    # for roles array stored in db... take each value, see if it matches the second column in the roles_enum array, if so, retu the 1st col of the enum as a uprcase,space_to_underscore,symbol .
    begin
      # roles array (enum)
      chosen_roles = self.roles.map { |r| r.blank? ? nil : ROLES[r.to_i - 1] }
      chosen_roles.compact.include? role
    rescue
      # single role
      # ROLES[self.roles.to_i - 1] == role
      # Rails.logger.debug "ROLES: #{self.roles.to_s}"
      self.roles.to_s == role.to_s
    end
  end

  def roles
    ROLES[super.to_i - 1]
  end

  RailsAdmin.config do |config|
    config.model self.name.underscore.capitalize.constantize do
    # rails_admin do
      navigation_label I18n.t("admin.settings.label")
      navigation_icon 'fa fa-user-circle'
      desc I18n.t("activerecord.descriptions.user")

      weight 1000
      # Field present Everywhere
      field :email do
        required true
      end
      field :username do
        required true
      end
      field :admin do
        visible do
          bindings[:view].current_user.admin? && bindings[:view].current_user.id != bindings[:object].id
        end
      end
      field :locked do
        visible do
          bindings[:view].current_user.admin? && bindings[:view].current_user.id != bindings[:object].id
        end
      end
      field :roles, :enum do
        visible !ROLES.blank?
        pretty_value do # used in list view columns and show views, defaults to formatted_value for non-association fields
          begin
            value.map { |v| bindings[:object].roles_enum.rassoc(v)[0] rescue nil }.compact.join ", "
          rescue
            I18n.t "roles.#{ROLES[value.to_i - 1]}"
          end
        end
        export_value do
          begin
            value.map { |v| bindings[:object].roles_enum.rassoc(v)[0] rescue nil }.compact.join ", " # used in exports, where no html/data is allowed
          rescue
            I18n.t "roles.#{ROLES[value.to_i - 1]}"
          end
        end
        queryable false
      end
      # include UserRailsAdminConcern

      # Fields only in lists and forms
      list do
        field :created_at
        configure :email do
          visible false
        end
        exclude_fields :lock_version
        field :authentication_token
        # include UserRailsAdminListConcern
      end
      show do
        #exclude_fields :id
        exclude_fields :lock_version
      end
      create do
        field :password do
          required true
        end
        field :password_confirmation do
          required true
        end
        field :lock_version, :hidden do
          visible true
        end
        # include UserRailsAdminCreateConcern
      end
      edit do
        field :password do
          required false
        end
        field :password_confirmation do
          required false
        end

        field :lock_version, :hidden do
          visible true
        end
        # include UserRailsAdminEditConcern
      end
    end
  end

  #has_paper_trail

  private

  def generate_authentication_token
    loop do
      self.authentication_token = SecureRandom.base64(64)
      break unless User.find_by(authentication_token: authentication_token)
    end
  end
end
