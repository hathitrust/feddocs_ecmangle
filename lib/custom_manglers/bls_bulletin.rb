# frozen_string_literal: true

require 'ecmangle'
module ECMangle
  # Bulletin of the BLS series
  class BLSBulletin < ECMangle::DefaultMangler
    def initialize
      @title = 'Bulletin of the United States Bureau of Labor Statistics'
      @ocns = [1_714_756, 604_255_105]
      super

      @patterns = @patterns.concat(
        [
          # Number:1116, Part:12, Volume:1
          %r{^
             #{@tokens[:n]}#{@tokens[:div]}
             #{@tokens[:pt]}#{@tokens[:div]}
             #{@tokens[:v]}
          $}xi,

          # NO. 562-565
          /^NO.\s(?<start_number>\d{3,4})-(?<end_number>\d{3,4})$/xi,
          # NO. 908:14 (1949)
          # NO. 3040:60
          # NO. 1370:18(1984)
          /^#{@tokens[:n]}:(?<part>\d{1,2})(\s?\(?#{@tokens[:y]}\))?$/xi,
          # 1312:8 (1972)
          /^(?<number>\d{3,4})#{@tokens[:div]}(?<part>\d{1,2})(\s\((?<year>\d{4})\))?$/xi,
          # 3000:26-50 (1980)
          /^(?<number>\d{3,4})#{@tokens[:div]}(?<start_part>\d{1,2})-(?<end_part>\d{1,2})(\s\((?<year>\d{4})\))?$/xi,
          # 2352-2354 (1990)
          /^(?<start_number>\d{4})-(?<end_number>\d{4})(\s\((?<year>\d{4})\))?$/xi,

          # NO. 2379(1991)
          /^#{@tokens[:n]}\((?<year>\d{4})\)$/xi,
          # NO. 609 YR. 1934
          /^#{@tokens[:n]}#{@tokens[:div]}#{@tokens[:y]}$/xi,
          # NO. 931-945 (1947-1948)
          # NO. 1017-1030 1950-1951
          /^#{@tokens[:ns]}\s?\(?(?<start_year>\d{4})-(?<end_year>\d{2,4})\)?$/xi,
          # NO. 1312 PT. 4 1966
          # NO. 1685PT. 53 1971
          /^#{@tokens[:n]}(#{@tokens[:div]})?#{@tokens[:pt]}\s#{@tokens[:y]}$/xi,
          # NO. 2025PT. 44-59
          /^#{@tokens[:n]}PT\.\s?(?<start_part>\d{1,2})-(?<end_part>\d{1,2})$/xi,
          # NO. 3090,PT. 17-21
          # NO. 1950,PT. 21-40 1977
          # NO. 1575:31-60 (1968)
          /^#{@tokens[:n]}#{@tokens[:div]}(PT.\s)?(?<start_part>\d{1,2})-(?<end_part>\d{1,2})(\s\(?(?<year>\d{4})\)?)?$/xi,
          # V. 932-944
          /^V.\s(?<start_number>\d{3,4})-(?<end_number>\d{3,4})$/xi,
          # V. 1775:40-61
          %r{^V.\s(?<number>\d{3,4})[:\/](?<start_part>\d{1,2})-(?<end_part>\d{1,2})$}xi,
          # NO. 1725PT. 96
          /^#{@tokens[:n]}PT\.\s(?<part>\d{1,2})$/xi,
          # NO. 2320:V. 2 (1989)
          # NO. 648/V. 5
          /^#{@tokens[:n]}#{@tokens[:div]}#{@tokens[:v]}(\s\((?<year>\d{4})\))?$/xi,
          # NO. 247-250,JAN-MAR
          # NO. 75-77 MAR-JULY 1908
          /^#{@tokens[:ns]}#{@tokens[:div]}#{@tokens[:m]}-#{@tokens[:m]}(\s(?<year>\d{4}))?$/xi,
          # NO. 148 V. 2 YR. 1914
          /^#{tokens[:n]}#{@tokens[:div]}#{@tokens[:v]}#{@tokens[:div]}#{@tokens[:y]}$/xi,
          # 441 (1927)
          # 441
          /^(?<number>\d{3,4})(\s\(?(?<year>\d{4})\)?)?$/xi,

          # V. 1502
          # V. 1312/8
          %r{^V.\s(?<number>\d{3,4})
          (#{@tokens[:div]}(?<part>\d{1,2}))?
          $}xi,

          # NO. 1370-13
          # NO. 1312-12 V. 1 1985
          # NO. 960-1 (1949)
          %r{^#{@tokens[:n]}#{@tokens[:div]}(?<part>\d{1,2})
          (\s#{@tokens[:v]})?
          (\s\(?(?<year>\d{4})\)?)?
          $}xi,

          # NO. 1312 PT. 12 V. 1 1985
          %r{^
            #{@tokens[:n]}\s
            #{@tokens[:pt]}\s
            #{@tokens[:v]}\s
            (?<year>\d{4})
          $}xi,

          # NO. 1265 PT. 1-30 1959-1960
          %r{^
            #{@tokens[:n]}#{@tokens[:div]}
            PT\.\s(?<start_part>\d{1,2})-(?<end_part>\d{1,2})
            \s\(?(?<start_year>\d{4})-(?<end_year>\d{2,4})\)?
          $}xi,

          # NO. 1465:1-30 (1965-66)
          %r{^
          #{@tokens[:n]}#{@tokens[:div]}
          (?<start_part>\d{1,2})-(?<end_part>\d{1,2})
          \s?\((?<start_year>\d{4})-(?<end_year>\d{2,4})\)
          $}xi,

          # NO. 1325 (1961/62)
          %r{^
          #{@tokens[:n]}#{@tokens[:div]}
          \((?<start_year>\d{4})[-\/](?<end_year>\d{2,4})\)
          $}xi,

          # NOS. 561-566 (1932)
          /^#{@tokens[:ns]}[\s\(]\(?#{@tokens[:y]}\)?$/xi,

          # NO. 600-606,1934
          /^#{@tokens[:ns]}#{@tokens[:div]}(?<year>\d{4})$/xi

        ]
      )
      # some people are calling them volumes instead of numbers
      # The first pattern matches them as volumes. Kill it.
      @patterns.shift
    end

    def parse_ec(ec_string)
      matchdata = nil

      ec_string = preprocess(ec_string).sub(/^C\. 1A /, '')
      @patterns.each do |p|
        break unless matchdata.nil?

        matchdata ||= p.match(ec_string)
      end

      unless matchdata.nil?
        ec = matchdata.named_captures
        ec = ECMangle.fix_months(ec)
        if ec.key?('end_year') && /^\d\d$/.match(ec['end_year'])
          ec['end_year'] = ec['start_year'][0, 2] + ec['end_year']
        elsif ec.key?('end_year') && /^\d\d\d$/.match(ec['end_year'])
          ec['end_year'] = ec['start_year'][0, 1] + ec['end_year']
        end
      end
      ec # ec string parsed into hash
    end

    def canonicalize(ec)
      t_order = %w[number part volume]
      canon = t_order.reject { |t| ec[t].nil? }
                     .collect { |t| t.to_s.tr('_', ' ').capitalize + ':' + ec[t] }
                     .join(', ')
      canon = nil if canon == ''
      canon
    end

    # take a parsed enumchron and expand it into its constituent parts
    # enum_chrons - { <canonical ec string> : {<parsed features>}, }
    def explode(ec, _src = nil)
      enum_chrons = {}
      return {} if ec.nil?

      ecs = []
      if ec['start_number']
        (ec['start_number']..ec['end_number']).each do |n|
          ecn = ec.clone
          ecn['number'] = n
          ecs << ecn
        end
      elsif ec['start_part']
        (ec['start_part']..ec['end_part']).each do |p|
          ecn = ec.clone
          ecn['part'] = p
          ecs << ecn
        end
      else
        ecs << ec
      end

      ecs.each do |ec|
        if canon = canonicalize(ec)
          ec['canon'] = canon
          enum_chrons[ec['canon']] = ec.clone
        end
      end
      enum_chrons
    end

    def self.load_context; end
    load_context
  end
end
