module Thecore
  module Generators
    class ThecorizePluginGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)

      # Something like:
      #
      class_option :git_server, aliases: "-g"

      def init_constants
        say "Setting the variables", :green
        @plugin_path = @destination_stack.first.match(Regexp.new("^.*#{@name}"))[0]
        @parent_path = File.expand_path("..", @plugin_path)
        @plugin_parent_name = @parent_path.split(File::SEPARATOR).last
        @plugin_initializers_dir = File.join(@plugin_path, "config", "initializers")
        @plugin_models_dir = File.join(@plugin_path, "app", "models")
        @plugin_lib_file = File.join(@plugin_path, "lib", @name, "engine.rb")
        Dir.chdir @plugin_models_dir do
          # Getting all the models that are activerecords:
          @model_files = Dir.glob("*.rb").map do |model|
            file = File.join(@plugin_models_dir,model)
            model if is_applicationrecord?(file)
          end.compact
        end
      end

      desc "Make migrations usable into main app"
      def migrations_to_main_app
        say "Checking if it's an engine"
        if is_engine?(@plugin_lib_file) && !has_add_to_migrations_declaration?(@plugin_lib_file)
          say "Adding migration reflection into engine.rb of", :green
          inject_into_file @plugin_lib_file, after: "class Engine < ::Rails::Engine\n" do
    "
        initializer '#{@name}.add_to_migrations' do |app|
          unless app.root.to_s == root.to_s
            # APPEND TO MAIN APP MIGRATIONS FROM THIS GEM
            config.paths['db/migrate'].expanded.each do |expanded_path|
              app.config.paths['db/migrate'] << expanded_path
            end
          end
        end

    "
          end
        end
      end

      desc "Add Ability File"
      def add_ability_file
        # do this just the first time
        say "Adding abilities file", :green
        abilities_file_name = "abilities_#{@name}_concern.rb"
        abilities_file_fullpath = File.join(@plugin_initializers_dir, abilities_file_name)
        initializer abilities_file_name do
    "require 'active_support/concern'

    module #{@name.classify}AbilitiesConcern
      extend ActiveSupport::Concern
      included do
        def #{@name}_abilities user
          if user
            # if the user is logged in, it can do certain tasks regardless his role
            if user.admin?
              # if the user is an admin, it can do a lot of things, usually
            end

            if user.has_role? :role
              # a specific role, brings specific powers
            end
          end
        end
      end
    end

    # include the extension
    TheCoreAbilities.send(:include, #{@name.classify}AbilitiesConcern)"
        end unless File.exists?(abilities_file_fullpath)
      end

      def manage_git
        say "Manage Git", :green
        rails_command "g thecorize_app #{@name}"
      end

      desc "Replace ActiveRecord::Base with ApplicationRecord"
      def replace_active_record
        say "Replace ActiveRecord::Base with ApplicationRecord", :green
        # For each model in this gem
        @model_files.each do |entry|
          # It must be a class and don't have rails_admin declaration
          file = File.join(@plugin_models_dir, entry)
          # say "Checking file #{file}", :red
          if is_activerecord?(file) && !has_rails_admin_declaration?(file)
            # say "Replacing ActiveRecord::Base into #{entry}", :green
            # Add rails admin declaration
            gsub_file file, "ActiveRecord::Base", "ApplicationRecord"
          end
        end
      end

      desc "Add rails_admin declaration only in files which are ActiveRecords and don't already have that declaration"
      def add_rails_admin_reference
        say "Add rails_admin declaration only in files which are ActiveRecords and don't already have that declaration", :green
        # For each model in this gem
        @model_files.each do |entry|
          # It must be a class and don't have rails_admin declaration
          file = File.join(@plugin_models_dir,entry)
          # say "Checking file #{file}", :red
          if is_applicationrecord?(file) && !has_rails_admin_declaration?(file)
            # say "Adding rails_admin to #{entry}", :green
            # Add rails admin declaration
            inject_into_file file, before: /^end/ do
    "
    rails_admin do
      navigation_label I18n.t('admin.settings.label')
      navigation_icon 'fa fa-file'
    end
    "
            end
          end
        end
      end

      desc "Completes Belongs To Associations"
      def complete_belongs_to
        say "Completes Belongs To Associations", :green
        # For each model in this gem
        @model_files.each do |entry|
          # It must be a class and don't have rails_admin declaration
          file = File.join(@plugin_models_dir,entry)
          # say "Checking file #{file}", :red
          if is_applicationrecord?(file)
            # say "Adding inverse_of to all belongs_to in #{entry}", :green
            # belongs_to that don't have inverse_of
            gsub_file file, /^(?!.*inverse_of.*)^[ \t]*belongs_to.*$/ do |match|
              match << ", inverse_of: :#{entry.split(".").first.pluralize}"
            end
          end
        end
      end

      desc "Add Has Many Associations"
      def add_has_many
        say "Add Has Many Associations", :green
        # For each model in this gem
        @model_files.each do |entry|
          file = File.join(@plugin_models_dir,entry)
          # It must be an activerecord model class
          if is_applicationrecord?(file)
            # say "Looking for belongs_to in #{entry} and adding the relevant has_manies", :green

            # Polymorphic must be managed manually
            File.readlines(file).grep(/^(?!.*polymorphic.*)^[ \t]*belongs_to :(.*),.+/).each do |a|
              target_association = a[/:(.*?),/,1]
              # look if the file identified by association .rb exists
              associated_file = File.join(@plugin_models_dir,"#{target_association}.rb")
              starting_model = entry.split(".").first.pluralize
              # say "Found belongs_to association: #{target_association} for the model: #{starting_model}", :green
              # say "- Looking for model file: #{associated_file}", :green
              if File.exists?(associated_file)
                # say "The file in which to add has_many, exists and the has_many does not! #{associated_file}", :green
                # if true, check that the association is non existent and add the association to that file
                inject_into_file associated_file, after: " < ApplicationRecord\n" do
    "  has_many :#{starting_model}, inverse_of: :#{target_association}, dependent: :destroy
    "
                end unless has_has_many_association?(associated_file, starting_model)
              else
                # otherwise (the file does not exist) check if the initializer for concerns exists,
                # For each model in this gem
                initializer_name = "associations_#{target_association}_concern.rb"
                initializer initializer_name do
    "require 'active_support/concern'

    module #{target_association.classify}AssociationsConcern
      extend ActiveSupport::Concern
      included do
      end
    end

    # include the extension
    #{target_association.classify}.send(:include, #{target_association.classify}AssociationsConcern)
    "
                end unless File.exists?(File.join(@plugin_initializers_dir, initializer_name))

                # then add to it the has_many declaration
                # TODO: only if it doesn't already exists
                inject_into_file File.join(@plugin_initializers_dir, initializer_name), after: "included do\n" do
    "    has_many :#{starting_model}, inverse_of: :#{target_association}, dependent: :destroy
    "
                end
              end
            end
          end
        end
      end

      desc "Add Has Many Through Associations"
      def add_has_many_through
        say "Add Has Many Through Associations", :green
        # I'ts just an approximation, but for now it could work
        @model_files.each do |model|
          association_model = model.split(".").first
          file = File.join(@plugin_models_dir,model)
          # It must be an activerecord model class
          model_with_belongs_to = File.readlines(file).grep(/^[ \t]*belongs_to :.*$/)
          if model_with_belongs_to.size == 2
            if yes?("Is #{model} an association model for a has_many through relation?", :red)
              # getting both the belongs_to models, find their model files, and add the through to each other
              left_side = model_with_belongs_to.first[/:(.*?),/,1]
              right_side = model_with_belongs_to.last[/:(.*?),/,1]
              # This side of the through
              inject_into_file File.join(@plugin_models_dir, "#{left_side}.rb"), after: " < ApplicationRecord\n" do
                #has_many :rooms, through: :chosen_rooms, inverse_of: :chosen_decks
    "  has_many :#{right_side.pluralize}, through: :#{association_model.pluralize}, inverse_of: :#{left_side.pluralize}
    "
              end unless is_has_many_through? file, right_side.pluralize, association_model.pluralize
              # Other side of the through
              inject_into_file File.join(@plugin_models_dir, "#{right_side}.rb"), after: " < ApplicationRecord\n" do
                #has_many :rooms, through: :chosen_rooms, inverse_of: :chosen_decks
    "  has_many :#{left_side.pluralize}, through: :#{association_model.pluralize}, inverse_of: :#{right_side.pluralize}
    "
              end unless is_has_many_through? file, left_side.pluralize, association_model.pluralize
            end
          end
        end
      end

      desc "Detect polymorphic Associations"
      def detect_polymorphic_associations
        say "Detect polymorphic Associations", :green
        # For each model in this gem
        # say "MODEL FILES: #{@model_files.inspect} "
        @model_files.each do |model|
          file = File.join(@plugin_models_dir,model)
          # It must be an activerecord model class
          # belongs_to :rowable, polymorphic: true, inverse_of: :rows
          polymorphics = File.readlines(file).grep(/^[ \t]*belongs_to :.*polymorphic.*/)
          polymorphics.each do |polymorphic_belongs_to|
            polymorphic_target_association = polymorphic_belongs_to[/:(.*?),/,1]
            # Just keeping the models that are not this model, and
            answers = ask_question_multiple_choice @model_files.reject {|m| m == model || has_polymorphic_has_many?(File.join(@plugin_models_dir,m), polymorphic_target_association)}, "Where do you want to add the polymorphic has_many called #{polymorphic_target_association} found in #{model}?"
            answers.each do |answer|
              # Add the polymorphic has_name declaration
              inject_into_file File.join(@plugin_models_dir, answer), after: " < ApplicationRecord\n" do
    "  has_many :#{model.split(".").first.pluralize}, as: :#{polymorphic_target_association}, inverse_of: :#{answer.split(".").first.singularize}, dependent: :destroy
    "
              end
            end
          end
        end
      end

      private

      def ask_question_multiple_choice models, question = "Choose among one of these, please."
        return [] if models.empty?
        # raccolgo tutte le risposte che non siano cancel
        # e ritorno l'array
        return_array = []
        while (answer ||= "") != "cancel"
          remaining_models = (models-return_array)
          break if remaining_models.empty?
          answer = ask question, :red, limited_to: remaining_models.push("cancel").uniq
          break if answer == "cancel"
          return_array.push answer
        end
        return return_array
      end

      def is_has_many_through? file, assoc, through
        (File.readlines(file).grep(/^[ \t]*has_many[ \t]+:#{assoc},[ \t]+through:[ \t]+:#{through}.*/).size > 0) rescue false
      end

      def has_polymorphic_has_many? file, polymorphic_name
        (File.readlines(file).grep(/^[ \t]*has_many.+as: :#{polymorphic_name}.*/).size > 0) rescue false
      end

      def is_activerecord? file
        (File.readlines(file).grep(/^class [A-Za-z0-9]+ < ActiveRecord::Base/).size > 0) rescue false
      end

      def is_applicationrecord? file
        (File.readlines(file).grep(/^class [A-Za-z0-9]+ < ApplicationRecord/).size > 0) rescue false
      end

      def has_rails_admin_declaration? file
        (File.readlines(file).grep(/^[ \t]*rails_admin do/).size > 0) rescue false
      end

      def is_engine? file
        (File.readlines(file).grep(/^[ \t]*class Engine < ::Rails::Engine/).size > 0) rescue false
      end

      def has_add_to_migrations_declaration? file
        (File.readlines(file).grep(/^[ \t]*initializer '[a-zA-Z0-9]+\.add_to_migrations' do \|app\|/).size > 0) rescue false
      end

      def has_has_many_association? file, assoc
        reg_def = "^[ \\t]+has_many[ \\t]+:#{assoc}"
        (File.readlines(file).grep(Regexp.new(reg_def)).size > 0) rescue false
      end
    end
  end
end
