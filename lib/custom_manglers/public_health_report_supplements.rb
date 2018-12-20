# frozen_string_literal: true

require 'ecmangle'
module ECMangle
  # Processing for Public Health Report Supplements series
  class PublicHealthReportSupplements < ECMangle::DefaultMangler
    def initialize
      @title = 'Public Health Report Supplements'
      @ocns = [29_651_249, 491_280_576]
      super
    end

    def self.title
      'Public Health Report Supplements'
    end

    def parse_ec(ec_string)
      matchdata = nil

      # fix 3 digit years, this is more restrictive than most series specific
      # work.
      ec_string = '1' + ec_string if ec_string.match?(/^9\d\d$/)

      @patterns.each do |p|
        break unless matchdata.nil?

        matchdata ||= p.match(ec_string)
      end

      # some cleanup
      unless matchdata.nil?
        ec = matchdata.named_captures
        # Fix months
        ec = ECMangle.fix_months(ec)

        # Remove nils
        ec.delete_if { |_k, value| value.nil? }

        # year unlikely. Probably don't know what we think we know.
        # From the regex, year can't be < 1800
        ec = nil if ec['year'].to_i > (Time.now.year + 5)
      end
      ec
    end

    def explode(ec, _src = nil)
      enum_chrons = {}
      return {} if ec.nil?

      ecs = [ec]
      ecs.each do |enum|
        if (canon = canonicalize(enum))
          enum['canon'] = canon
          enum_chrons[enum['canon']] = enum.clone
        end
      end
      enum_chrons
    end

    def canonicalize(ec)
      t_order = %w[volume number part year]
      canon = t_order.reject { |t| ec[t].nil? }
                     .collect { |t| t.to_s.tr('_', ' ').capitalize + ':' + ec[t] }
                     .join(', ')
      canon = nil if canon == ''
      canon
    end
  end
end
