# frozen_string_literal: true

require 'ecmangle'
module ECMangle
  class DecisionsOfTheCourtOfVeteransAppeals < ECMangle::DefaultMangler
    def initialize
      @title = 'Decisions of the Court of Veterans Appeals'
      @ocns = [27_093_456]
      super

      # tokens
      div = '[\s:,;\/-]+\s?\(?'
      n = 'N(umber|O)\.?' + div + '(?<number>\d{2}-\d{2,4})'
      y = 'Y(ear|R)\.?\s?(?<year>\d{4})'
      month = '(?<month>(JAN|FEB|MAR(CH)?|APR(IL)?|MAY|JUNE?|JULY?|AUG|SEPT?|OCT|NOV|DEC)\.?)'

      @patterns = [
        # canonical
        # Number:98-8551
        # Number:98-8551-3, Decision Date:2005-05-16
        %r{
          ^#{n}
          (-(?<decision>\d))?
          (,\sDecision\sDate:(?<year>\d{4})(-(?<month>\d{2}))?(-(?<day>\d{2}))?)?$
        }x,

        # NO. 98-1348 (2001:JAN. 10)
        # NO. 95-1100/999 (1999:APR. 1)
        # NO. 95-1068/999-2 (1999:MAR. 24)
        %r{
          ^#{n}
          (\/(?<decision_year>\d{3,4}))?
          ([\/-](?<decision>\d))?\s?
          (\((?<year>\d{4}):#{month}\s?
          (?<day>\d{1,2})?\))?$
        }x,

        # 98-1348
        # 95-1068/998
        # 92-561/2
        %r{
          ^(?<number>\d{2}-\d{2,4})
          (\/(?<year>\d{3,4}))?
          ([\/-](?<decision>\d))?$
        }x,

        # 1990:753/2
        # 1998:57/2002-2
        %r{
          ^(?<case_year>\d{4}):
          (?<number>\d+)
          (\/(?<year>\d{3,4}))?
          ([\/-](?<decision>\d))?$
        }x,

        # stupid
        # 91-5041992:FEB. 21
        %r{
          ^(?<number>\d{2}-\d{2,4})
          ((?<year>\d{4}):#{month}\s?
          (?<day>\d{1,2})?)?$
        }x,

        # simple year
        %r{
          ^#{y}$
        }x
      ] # patterns
    end

    def parse_ec(ec_string)
      # our match
      matchdata = nil

      ec_string = ec_string.chomp.sub(/^TN23 \. U43 /, '')

      @patterns.each do |p|
        break unless matchdata.nil?

        matchdata ||= p.match(ec_string)
      end

      unless matchdata.nil?
        ec = matchdata.named_captures
        ec.delete_if { |_k, v| v.nil? }

        # the two years in the enumchron need to match
        if ec['decision_year']
          ec['decision_year'] = ECMangle.correct_year(ec['decision_year'])
        end

        ec['year'] = ECMangle.correct_year(ec['year']) if ec['year']

        ec['year'] = ec['decision_year'] if ec['decision_year'] && !ec['year']

        if ec['month'] && ec['month'] =~ /^[0-9]+$/
          ec['month'] = ECMangle::MONTHS[ec['month'].to_i - 1]
        end

        # sometimes the number lacks the case year prefix, reassemble
        # e.g. 1990:753/2
        if ec['number'] && ec['number'] !~ /-/ && (ec['case_year'].length == 4)
          ec['number'] = ec['case_year'][2, 2,] + '-' + ec['number']
        end

        if ec['year'] && ec['decision_year'] && (ec['year'] != ec['decision_year'])
          # We don't actually understand this enumchron
          ec = nil
        end

      end
      ec
    end

    def explode(ec, _src = nil)
      enum_chrons = {}
      return {} if ec.nil?

      ecs = []
      ecs << ec

      ecs.each do |ec|
        if canon = canonicalize(ec)
          ec['canon'] = canon
          enum_chrons[ec['canon']] = ec.clone
        end
      end

      enum_chrons
    end

    def canonicalize(ec)
      # Number:8560
      if ec['number']
        canon = "Number:#{ec['number']}"
        canon += "-#{ec['decision']}" if ec['decision']
      end
      if ec['year']
        canon += ", Decision Date:#{ec['year']}"
        if ec['month']
          month_num = (ECMangle::MONTHS.index(ECMangle.lookup_month(ec['month'])) + 1).to_s.rjust(2, '0')
          canon += "-#{month_num}"
          canon += "-#{ec['day'].rjust(2, '0')}" if ec['day']
        end
      end
      canon
    end

    def self.load_context; end
    load_context
  end
end
