require 'active_support/concern'

module ActiveRecordPaperclipConcern
  extend ActiveSupport::Concern

  included do
    has_attached_file :asset, styles: {
      thumb: "100x100#",
      small: "150x150>",
      medium: "200x200>",
      large: "600x600>"
    }
    validates_attachment_content_type :asset, content_type: /\Aimage\/.*\Z/
    # add a delete_<asset_name> method:
    attr_accessor :delete_asset
    before_validation { self.asset.clear if self.delete_asset == '1' }
  end
end

# Do not auto include the asset, not all the models have it
# ActiveRecord::Base.send(:include, ActiveRecordPaperclipConcern)
