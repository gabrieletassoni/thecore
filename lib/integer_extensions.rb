require 'active_support/concern'

module FixnumConcern
  extend ActiveSupport::Concern
  included do
    def to_tiered_times skip_seconds = false
      # Actual calculations
      mm, ss = self.divmod(60)
      hh, mm = mm.divmod(60)
      dd, hh = hh.divmod(24)

      # Presentation
      sentence = []
      sentence << I18n.t("tiered_times.dd", count: dd) unless dd.zero?
      sentence << I18n.t("tiered_times.hh", count: hh) unless hh.zero?
      sentence << I18n.t("tiered_times.mm", count: mm) unless mm.zero?
      sentence << I18n.t("tiered_times.ss", count: ss) if !ss.zero? && !skip_seconds

      # to_sentence è una estensione rails che traduce nella forma più corretta (decisamente migliore del join(", "))
      sentence.to_sentence
    end
  end
end

# include the extension
Integer.send(:include, FixnumConcern)
