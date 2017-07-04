require 'rails/generators/named_base'
module Thecore
  class ThecorizeAppGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)

    def setup_variables
      @plugin_path = @destination_stack.first.match(Regexp.new("^.*#{@name}"))[0]
      @plugin_parent_name = @plugin_path.split(File::SEPARATOR).last
    end

    def remove_index
      #remove the index.html
      remove_file 'public/index.html'
    end
  end
end
