# frozen_string_literal: true

require 'ecmangle'
module ECMangle
  class PublicPapersOfThePresidents < ECMangle::DefaultMangler
    @presidents = []

    def initialize
      @title = 'Public Papers of the Presidents'
      @ocns = [1_198_154, 47_858_835]
      super
      # tokens
      y = '(Y(ear|R\.)?[:\s])?(?<year>\d{4})'
      ys = '(Years:\s?)?(?<start_year>\d{4})[-\/](?<end_year>\d{2,4})'
      b = 'B(OO)?K\.?[:\s](?<book>\d)'
      v = 'V(olume|\.)?[:\s]?(?<volume>\d{1,2})'
      p = 'P(art|T\.?)?[:\s]?(?<part>\w{1,2})'
      div = '[\s:,;\/-]+\s?\(?'
      ind = '(?<index>(INDEX|IND\.?))'
      app = '(?<appendix>(TECH\.?\s)?APP(EN)?D?I?X?\.?)'
      sec = 'SECT?(ION)?\.?[:\s]?(?<section>\d+)'
      sup = '(?<supplement>SUPP?(LEMENT)?\.?)'
      pres = '\(?(?<president>(' + self.class.presidents.join('|') + '))\)?'

      @patterns = [
        # canonical
        # Year:1960
        # Year:1960, Book:2
        # Year:1960, Volume:2
        # Year:1990, President:Bush
        %r{
          ^(#{y}|#{ys})
          (#{div}#{v})?
          (#{div}#{p})?
          (#{div}#{b})?
          (#{div}#{pres})?$
        }xi,

        # BK. 1 (1993)
        # BK. 1(2002)
        %r{
          ^#{b}
          \s?\(#{y}\)?$
        }x,

        # JOHNSON 1963-64: V. 2
        %r{
          ^#{pres}
          #{div}(#{y}|#{ys})
          (#{div}#{v})?$
        }x,

        # 1982PT2
        # 1982V. 1
        # 2007PT. 1 2007
        %r{
          ^(#{y}|#{ys})
          (#{p})?
          (#{v})?
          (#{b})?
          (\s(#{y}|#{ys}))?$
        }x,

        # V. 2 (1997)
        # V. 3
        %r{
          ^#{v}
          (#{div}(#{y}|#{ys})\))?$
        }x,

        # INDEX 1977/1981
        # INDEX 1993-2001 1993-2001
        %r{
          ^#{ind}
           #{div}(#{y}|#{ys})
           (#{div}(#{y}|#{ys}))?$
        }x,

        # 953-61/IND.
        %r{
          ^(#{y}|#{ys})
          #{div}#{ind}$
        }x,

        # 1963/64 2
        # 1965 1
        %r{
          ^(#{y}|#{ys})
          \s(?<book>\d)$
        }x,

        # we don't care about months/days, book tells us that already
        # 1993:BOOK 1 (1993:JAN. 20/JULY 31)
        # 2003:BK. 2 (JULY 1/DEC. 31)
        # 2004:BK. 2 (JULY. 1/SEPT. 30)
        # 2008:BK. 1(JAN. 1/JUNE 30)
        %r{
          ^#{y}
          #{div}#{b}
          \s?\((\d{4}:)?
          [A-Z]{3,4}\.?\s\d{1,2}
          \/(\d{4}:)?[A-Z]{3,4}\.?\s\d{1,2}\)$
        }x,

        # BK. 2 (1992/93)
        %r{
          ^#{b}
          #{div}#{ys}\)$
        }x,

        # BK. 2(2011:JULY 01/DEC. 31)
        %r{
          ^#{b}
          \s?\((?<year>\d{4}):
          [A-Z]{3,4}\.?\s\d{1,2}\/
          [A-Z]{3,4}\.?\s\d{1,2}\)$
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

      ec_string = ECMangle.remove_dupe_years(ec_string.chomp)
      # remove copy info
      ec_string = preprocess(ec_string).chomp
      ec_string.gsub!(/ C\. \d$/, '')

      # fix the three digit years
      ec_string = '1' + ec_string if ec_string.match?(/^[89]\d\d[^0-9]*/)
      # seriously
      ec_string = '2' + ec_string if ec_string.match?(/^0\d\d[^0-9]*/)

      @patterns.each do |p|
        break unless matchdata.nil?

        matchdata ||= p.match(ec_string)
      end

      unless matchdata.nil?
        ec = matchdata.named_captures
        ec.delete_if { |_k, v| v.nil? }
        if ec.key? 'end_year'
          ec['end_year'] = ECMangle.calc_end_year(ec['start_year'], ec['end_year'])
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
      canon = []
      canon << "Year:#{ec['year']}" if ec['year']
      canon << "Years:#{ec['start_year']}-#{ec['end_year']}" if ec['start_year']
      canon << "Volume:#{ec['volume']}" if ec['volume']
      canon << "Part:#{ec['part']}" if ec['part']
      canon << "Book:#{ec['book']}" if ec['book']
      canon << "President:#{ec['president']}" if ec['president']
      canon << 'Index' if ec['index']
      canon.join(', ') unless canon.empty?
    end

    class << self
      attr_reader :presidents
    end

    def self.load_context
      pres = File.dirname(__FILE__) + '/data/presidents.txt'
      File.open(pres).each do |line|
        @presidents << line.chomp
      end
    end
    load_context
  end
end
