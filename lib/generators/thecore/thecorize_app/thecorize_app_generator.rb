require 'rails/generators/named_base'
module Thecore
  class ThecorizeAppGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def remove_index
      #remove the index.html
      remove_file 'public/index.html'
    end
  end
end
