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
  end
end
