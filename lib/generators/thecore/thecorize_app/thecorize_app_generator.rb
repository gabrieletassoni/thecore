require 'rails/generators/named_base'
module Thecore
  class ThecorizeAppGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def remove_index
      #remove the index.html
      remove_file 'public/index.html'
    end

    # TODO: Must add
    # *= require thecore to application.css before */
    # //= require thecore to application.js before //= require_tree .
    def manage_assets
      inject_into_file 'app/assets/javascripts/application.js', before: "//= require_tree ." do <<-'RUBY'
        puts "//= require thecore"
        RUBY
      end
      inject_into_file 'app/assets/stylesheets/application.css', before: "*/ ." do <<-'RUBY'
        puts "*= require thecore"
        RUBY
      end
    end

    # TODO: remove from application controller the protect_from_forgery with: :exception part
    def adapt_application_controller_to_devise
      gsub_file 'app/controllers/application_controller.rb', 'protect_from_forgery with: :exception', ''
    end

    # TODO: add a .gitignore good for Rails and manage git
    # "Traversing the DIR structures it adds git remote URL", "By checking wether or not the .git folder exists, it inits or changes the url."
    def update_or_init_git_remote
      template "gitignore.rails" ".gitignore"
      git :init
      git add: "."
      git commit: "-m First commit!"
    end
  end
end
