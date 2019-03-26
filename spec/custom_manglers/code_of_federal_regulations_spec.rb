# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'FederalRegulations' do
  let(:fr) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/code_of_federal_regulations.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/federal_regulations_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = fr.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts fr.canonicalize(ec)
          res = fr.explode(ec)
          res.each do |canon, _features|
            #puts canon
          end
          matches += 1
        end
      end
      puts "Code of Federal Regulations match: #{matches}"
      puts "Code of Federal Regulations no match: #{misses}"
      # actual number in test file is 10928
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(10_068)
    end

    it 'parses canonical' do
      expect(
        fr.parse_ec(
          'Title:31, Chapter:4, Start Chapter:5, End Chapter:6, Part:54, Start Part:3, End Part:8, Section:6, Year:1984'
        )['end_part']
      ).to eq('8')
    end

    it 'parses "TITLE 8 1962"' do
      expect(fr.parse_ec('TITLE 8 1962')['title']).to eq('8')
      expect(fr.parse_ec('(TITLE) 8 1962')['title']).to eq('8')
      expect(fr.parse_ec('TITLE 44-45 1949')['title']).to eq('44-45')
      expect(fr.parse_ec('TITLE 40 PT. 86 2008')['part']).to eq('86')
    end

    it 'parses "TITLE 49 1973 PT. 1300-END"' do
      expect(fr.parse_ec('TITLE 49 1973 PT. 1300-END')['end_part']).to eq('END')
    end

    it 'parses "TITLE 7 PT. 300-699 1994"' do
      expect(fr.parse_ec('TITLE 7 PT. 300-699 1994')['end_part']).to eq('699')
    end

    it 'parses "(TITLE) 7:1030-1059 1962"' do
      expect(fr.parse_ec('(TITLE) 7:1030-1059 1962')['end_part']).to eq('1059')
    end

    it 'parses "44 (1999)"' do
      expect(fr.parse_ec('44 (1999)')['title']).to eq('44')
      expect(fr.parse_ec('NO. 25 1993')['title']).to eq('25')
    end

    it 'parses "7:PT. 400/699 (1999)"' do
      expect(fr.parse_ec('7:PT. 400/699 (1999)')['title']).to eq('7')
    end

    it 'parses "2014 T. 21 800-1299 2014"' do
      expect(fr.parse_ec('2014 T. 21 800-1299 2014')['title']).to eq('21')
      expect(fr.parse_ec('2014 T. 47 0-19 2014')['title']).to eq('47')
    end

    it 'parses "TITLE 48 1986 CH. 2"' do
      expect(fr.parse_ec('TITLE 48 1986 CH. 2')['chapter']).to eq('2')
      expect(fr.parse_ec('TITLE 48 1989 CH. 3-6')['start_chapter']).to eq('3')
      expect(fr.parse_ec('TITLE 48 1985 CH. 1 PT. 52-99')['start_part']).to eq('52')
    end

    it 'parses "(TITLE) 7:52 1968"' do
      expect(fr.parse_ec('(TITLE) 7:52 1968')['title']).to eq('7')
      expect(fr.parse_ec('TITLE 7 1984 PT. 52')['part']).to eq('52')
    end

    it 'parses "TITLE 26 1999 PT. 1 SEC. 1. 441-1. 500"' do
      expect(fr.parse_ec('TITLE 26 1999 PT. 1 SEC. 1. 441-1. 500')['section']).to eq('1. 441-1. 500')
      expect(fr.parse_ec('TITLE 26 1997 PT. 1(1. 170-1. 300)')['section']).to eq('1. 170-1. 300')
      expect(fr.parse_ec('TITLE 26 PT. 1 (SEC. 1. 908-1. 1000) 2001')['section']).to eq('1. 908-1. 1000')
      expect(fr.parse_ec('TITLE 26 1969 PT. 1. 501-1. 640')['section']).to eq('1. 501-1. 640')
      expect(fr.parse_ec('TITLE 26 PT. 1. 851-1. 907 2010')['section']).to eq('1. 851-1. 907')
      expect(fr.parse_ec('TITLE 26 1969 PT. 1. 501-1. 640')['part']).to be_nil
    end

    it 'parses "TITLE 26 PT. 1 SEC. 301-400 2002"' do
      expect(fr.parse_ec('TITLE 26 PT. 1 SEC. 301-400 2002')['section']).to eq('301-400')
    end

    it 'parses " 40:PT. 52:SECT. 52. 1019/END (2004)"' do
      expect(fr.parse_ec('40:PT. 52:SECT. 52. 1019/END (2004)')['section']).to eq('52. 1019/END')
      expect(fr.parse_ec('40:PT. 63:SECT. 63. 1440/63. 8830 (2004)')['section']).to eq('63. 1440/63. 8830')
    end

    it 'parses "48:CHAP. 15/28 (2004)"' do
      expect(fr.parse_ec('48:CHAP. 15/28 (2004)')['end_chapter']).to eq('28')
      expect(fr.parse_ec('48:CHAP. 1:PT. 1/51 (1999)')['end_part']).to eq('51')
      expect(fr.parse_ec('41:CHAP. 201/END (1999)')['end_chapter']).to eq('END')
    end

    it 'parses "TITLE 48 CH. 2 PT. 201-299 2002"' do
      expect(fr.parse_ec('TITLE 48 CH. 2 PT. 201-299 2002')['end_part']).to eq('299')
    end

    it 'parses "1999 T. 35 1999"' do
      expect(fr.parse_ec('1999 T. 35 1999')['title']).to eq('35')
      expect(fr.parse_ec('2013 T. 31 500-END 2013')['end_part']).to eq('END')
      expect(fr.parse_ec('2014 T. 26 1(1. 441-1. 500) 2014')['section']).to eq('1. 441-1. 500')
      expect(fr.parse_ec('1997 T. 9 (1-199) 1997')['end_part']).to eq('199')
      expect(fr.parse_ec('1997 T. 9 (200-END) 1997')['end_part']).to eq('END')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(fr.canonicalize({})).to be_nil
    end

    it 'gives title then year for canonical' do
      parsed = fr.parse_ec('TITLE 8 1962')
      expect(fr.canonicalize(parsed)).to eq('Title:8, Year:1962')
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(fr.ocns).to include(2_786_662)
    end
  end
end
