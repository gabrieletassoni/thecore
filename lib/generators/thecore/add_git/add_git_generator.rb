require 'rails/generators/named_base'
module Thecore
  class AddGitGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

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
