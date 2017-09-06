module ThecoreHelper
  def bootstrap_class_for(flash_type)
    {
        success: "alert-success",
        error: "alert-error",
        alert: "alert-danger",
        notice: "alert-info"
    }[flash_type.to_sym] || flash_type.to_s
  end

  def bootstrap_glyphs_icon(flash_type)
    {
        success: "glyphicon-ok",
        error: "glyphicon-exclamation-sign",
        alert: "glyphicon-warning-sign",
        notice: "glyphicon-info-sign"
    }[flash_type.to_sym] || 'glyphicon-screenshot'
  end

  def title(title)
    content_for(:title) { title }
  end

  def meta_description(meta_description)
    content_for(:meta_description) { meta_description }
  end

  def og_title(og_title)
    content_for(:og_title) { og_title }
  end

  def og_description(og_description)
    content_for(:og_description) { og_description }
  end

  def og_image(og_image)
    content_for(:og_image) { og_image }
  end

  def bootstrap_class_for(flash_type)
    case flash_type
    when 'success'
      'alert-success'
    when 'error'
      'alert-danger'
    when 'alert'
      'alert-warning'
    when 'notice'
      'alert-info'
    else
      flash_type.to_s
    end
  end
end
