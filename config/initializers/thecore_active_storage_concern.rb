# require 'active_support/concern'

# module ThecoreActiveStorageBlobConcern
#     extend ActiveSupport::Concern
    
#     included do
#         rails_admin do
#             visible false
#         end
#     end
# end

# module ThecoreActiveStorageAttachmentConcern
#     extend ActiveSupport::Concern
    
#     included do
#         rails_admin do
#             visible false
#         end
#     end
# end

RailsAdmin.config do |config|
    config.model "ActiveStorage::Blob" do
        visible false
    end
end

RailsAdmin.config do |config|
    config.model "ActiveStorage::Attachment" do
        visible false
    end
end

RailsAdmin.config do |config|
    config.model "Ckeditor::Asset" do
        visible false
    end
end

RailsAdmin.config do |config|
    config.model "Ckeditor::AttachmentFile" do
        visible false
    end
end

RailsAdmin.config do |config|
    config.model "Ckeditor::Picture" do
        visible false
    end
end