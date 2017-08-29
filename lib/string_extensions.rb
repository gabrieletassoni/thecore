# .gsub(/[^A-Za-z0-9]/, " ").split.join("%")
require 'active_support/concern'

module StringConcern
  extend ActiveSupport::Concern

  def likeize
    strip.gsub(/[^A-Za-z0-9]/, " ").split.select{|w| w.length > 2}.join("%")
  end
end

# include the extension
String.send(:include, StringConcern)
