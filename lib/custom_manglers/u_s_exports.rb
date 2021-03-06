# frozen_string_literal: true

require 'ecmangle'
module ECMangle
  # Processing for U.S. Exports series
  class USExports < ECMangle::DefaultMangler
    def initialize
      @title = 'U.S. Exports'
      @ocns = [1_799_484, 698_024_555]
      super

      @patterns << /^#{@tokens[:y]}#{@tokens[:div]}(?<month>\d{1,2})$/xi
      @patterns << /^#{@tokens[:y]}\(?#{@tokens[:m]}\s\)?$/xi
      @patterns << %r{^#{@tokens[:y]}#{@tokens[:div]}
        (?<start_month>\d{1,2})#{@tokens[:div]}
        (?<end_month>\d{1,2})$}xi
      @patterns << %r{^#{@tokens[:y]}#{@tokens[:div]}\d{1,2}#{@tokens[:div]}
        \(?#{@tokens[:m]}\s?\)?$}xi
      @patterns << %r{^#{@tokens[:y]}
        \(?\s?(?<start_month>#{@tokens[:m]})#{@tokens[:div]}{1,2}
        (?<end_month>#{@tokens[:m]})\s?\)?
        (\s?#{@tokens[:y]})?$}xi
      @patterns << %r{^(?<start_month>#{@tokens[:m]})#{@tokens[:div]}{1,2}
        (?<end_month>#{@tokens[:m]})#{@tokens[:div]}
        #{@tokens[:y]}
        (\s#{@tokens[:pt]})?$}xi
    end

    def preprocess(ec_string)
      ec_string = ec_string.sub(/^C. 1 /, '')
                           .sub(/ C. 1$/, '')
                           .sub(/#{@tokens[:div]}C. [12]$/, '')
      ec_string = '1' + ec_string if ec_string =~ /^9\d\d/
      # V. 1977:MAY-JUNE
      ec_string.sub(/^V. ([12]\d{3})/, '\1')
    end

    def parse_ec(ec_string)
      # our match
      matchdata = nil

      ec_string = preprocess(ec_string).chomp

      @patterns.each do |p|
        break unless matchdata.nil?

        matchdata ||= p.match(ec_string)
      end

      ec = ECMangle.fix_months(matchdata.named_captures) unless matchdata.nil?
    end

    def explode(ec, _src = nil)
      enum_chrons = {}
      return {} if ec.nil?

      ecs = []
      if ec['start_number']
        (ec['start_number']..ec['end_number']).each do |num|
          copy = ec.clone
          copy['number'] = num
          ecs << copy
        end
      else
        ecs << ec
      end

      ecs = [ec]

      ecs.each do |ec|
        if (canon = canonicalize(ec))
          ec['canon'] = canon
          enum_chrons[ec['canon']] = ec.clone
        end
      end
      enum_chrons
    end

    def canonicalize(ec)
      canon = []
      canon << "Volume:#{ec['volume']}" if ec['volume']
      canon << "Part:#{ec['part']}" if ec['part']
      canon << "Number:#{ec['number']}" if ec['number']
      if ec['start_number'] && !ec['number']
        start_num = ec['start_number'].to_i.to_s
        end_num = ec['end_number'].to_i.to_s
        canon << "Numbers:#{start_num}-#{end_num}"
      end
      canon << "Year:#{ec['year']}" if ec['year']
      canon << "Month:#{ec['month']}" if ec['month']
      if ec['start_month'] && !ec['month']
        canon << "Months:#{ec['start_month']}-#{ec['end_month']}"
      end
      canon.join(', ') unless canon.empty?
    end
  end
end
