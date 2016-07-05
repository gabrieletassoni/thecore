require 'active_support/concern'

module BulkDeleteConcern
  extend ActiveSupport::Concern
  included do
    def to_tiered_times skip_seconds
      skip_seconds ||= false

      # Actual calculations
      mm, ss = self.divmod(60)            #=> [4515, 21]
      hh, mm = mm.divmod(60)           #=> [75, 15]
      dd, hh = hh.divmod(24)           #=> [3, 3]

      # Presentation
      sentence = []
      sentence << I18n.t("tiered_times.dd", dd: dd) unless dd.blank?
      sentence << I18n.t("tiered_times.hh", hh: hh) unless hh.blank?
      sentence << I18n.t("tiered_times.mm", mm: mm) unless mm.blank?
      sentence << I18n.t("tiered_times.ss", ss: ss) if !ss.blank? && !skip_seconds

      sentence.join(", ")
    end
  end
end

# include the extension
RailsAdmin::Config::Actions::BulkDelete.send(:include, BulkDeleteConcern)
