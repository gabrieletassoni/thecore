module ApplicationHelper
  def title(value)
    unless value.nil?
      @title = "#{value} | Hifoundation"
    end
  end
end
