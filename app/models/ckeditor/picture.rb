class Ckeditor::Picture < Ckeditor::Asset
  has_attached_file :data,
                    url: '/ckeditor_assets/pictures/:id/:style_:basename.:extension',
                    path: ':rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension',
                    styles: { content: '800>', thumb: '118x100#' }

  validates_attachment_presence :data
  validates_attachment_size :data, less_than: 2.megabytes
  validates_attachment_content_type :data, content_type: /\Aimage/

  def url_content
    # url_t = (ENV['RAILS_URL'].blank? || ) ? "http://localhost:3000" : "#{ENV['RAILS_URL']}#{ENV['RAILS_RELATIVE_URL_ROOT']}"
    # "#{ENV['RAILS_URL'].presence || "http://localhost:3000"}#{ENV['RAILS_RELATIVE_URL_ROOT'].presence}#{url(:content)}"
    url(:content)
  end
end
