class ThecoreizeRailsPluginGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def initialize
    copy_file "gitignore", ".gitignore"

    gem 'thecore', path: '../../thecore_project/thecore'

    git :init
    git add: ".gitignore"
    git commit: "-m Added Gitignore"
    git add: "."
    git commit: "-m First commit!"
    git remote: "add origin https://github.com/username/your-repo-name.git"
  end

end
