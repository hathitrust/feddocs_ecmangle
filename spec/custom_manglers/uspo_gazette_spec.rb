# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'USPOGazette' do
  let(:g) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/uspo_gazette.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/uspo_gazette_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = g.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts g.canonicalize(ec)
          res = g.explode(ec)
          res.each do |canon, features|
            # puts "canon:#{canon}"
          end
          matches += 1
        end
      end
      puts "USPO Gazette match: #{matches}"
      puts "USPO Gazette no match: #{misses}"
      # actual number in test file is 8075
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(8007)
    end

    it 'parses canonical' do
      expect(
        g.parse_ec(
          'Volume:154, Part:2, Number:7, Start Number:5, End Number:8, Year:1980, Month:June, Day:20, Start Month:April, Start Day:10, End Month:July, End Day:20, Numbers:3,555,555-4,555,555'
        )['end_month']
      ).to eq('July')
    end

    it 'parses "V. 98 FE 1902"' do
      expect(g.parse_ec('V. 98 FE 1902')['month']).to eq('February')
      expect(g.parse_ec('V. 864 PT. 1 JL 1969')['month']).to eq('July')
      expect(g.parse_ec('V. 872 PT. 1 MR 1970')['month']).to eq('March')
      expect(g.parse_ec('V. 549 (1943)')['year']).to eq('1943')
    end

    it 'parses "V. 98 1902:FEB."' do
      expect(g.parse_ec('V. 98 1902:FEB.')['month']).to eq('February')
      expect(g.parse_ec('V. 97(1901:DEC. )')['month']).to eq('December')
      expect(g.parse_ec('V. 607 (1948:FEB. )')['month']).to eq('February')
      expect(g.parse_ec('V. 933:PT. 2(1975:APR. )')['month']).to eq('April')
    end

    it 'parses "V. 8151965:JUNE"' do
      expect(g.parse_ec('V. 8151965:JUNE')['volume']).to eq('815')
    end

    it 'parses "V. 518-5191940:SEPT. 3-OCT. 29"' do
      expect(g.parse_ec('V. 518-5191940:SEPT. 3-OCT. 29')['end_month']).to eq('October')
      expect(g.parse_ec('V. 520-5211940:NOV. -DEC.')['end_month']).to eq('December')
    end

    it 'parses "V. 69 OC-DE 1894"' do
      expect(g.parse_ec('V. 69 OC-DE 1894')['end_month']).to eq('December')
      expect(g.parse_ec('V. 87 APR. -MAY 1899')['end_month']).to eq('May')
    end

    it 'parses "V. 859,NOS. 1-2 1969:FEB."' do
      expect(g.parse_ec('V. 859,NOS. 1-2 1969:FEB.')['end_number']).to eq('2')
      expect(g.parse_ec('V. 812,PT. 1,NOS. 1-3 1965:MAR.')['end_number']).to eq('3')
    end

    it 'parses "V. 425 (1932:DEC. 6-27)"' do
      expect(g.parse_ec('V. 425 (1932:DEC. 6-27)')['end_day']).to eq('27')
    end

    it 'parses "2,690,560-2,692,986(1954)"' do
      expect(g.parse_ec('2,690,560-2,692,986(1954)')['numbers']).to eq('2,690,560-2,692,986')
      expect(g.parse_ec('2,288,589-2,291,596(1942:JULY)')['month']).to eq('July')
      expect(g.parse_ec('2,291,597-2,294,357(1942:AUG. )')['month']).to eq('August')
    end

    it 'parses "1,326,899-1,332,191(1920:JAN. 6-FEB. 24)"' do
      expect(g.parse_ec('1,326,899-1,332,191(1920:JAN. 6-FEB. 24)')['end_month']).to eq('February')
    end

    it 'parses "V. 852-853 JUL-AUG 1968"' do
      expect(g.parse_ec('V. 852-853 JUL-AUG 1968')['end_volume']).to eq('853')
      expect(g.parse_ec('V. 3-4 1873')['end_volume']).to eq('4')
    end

    it 'parses "V. 864:NO. 3-51969:JULY 15-29"' do
      expect(g.parse_ec('V. 864:NO. 3-51969:JULY 15-29')['end_day']).to eq('29')
    end

    it 'parses "V. 778 NO. 3-5 1962:MAY 15-MAY 29 1962 3,034,128-3,037,205"' do
      expect(g.parse_ec('V. 778 NO. 3-5 1962:MAY 15-MAY 29 1962 3,034,128-3,037,205')['numbers']).to eq('3,034,128-3,037,205')
      expect(g.parse_ec('V. 37, NO. 1-4 1886:OCT 5-OCT 26 1886 350,095-351,729')['numbers']).to eq('350,095-351,729')
      expect(g.parse_ec('V. 37, NO. 5-13 1886:NOV. 2- DEC. 28 1886 351,730-355,290')['end_day']).to eq('28')
      expect(g.parse_ec('V. 67, NO. 5-9 1894:MAY 1-MAY 29 518,934-520,760')['end_day']).to eq('29')
      expect(g.parse_ec('V. 46, NO. 10-13 1889:MAR. 5-MAR. 26 1889 398,812-400,421')['end_day']).to eq('26')
    end

    it 'parses "V. 766 NO. 1-3 1961:MAY 1961 2,981,954-2,984,835"' do
      expect(g.parse_ec('V. 766 NO. 1-3 1961:MAY 1961 2,981,954-2,984,835')['month']).to eq('May')
    end

    it 'parses "V. 76:1 (1896:JULY)"' do
      expect(g.parse_ec('V. 76:1 (1896:JULY)')['month']).to eq('July')
    end

    it 'parses "V. 99:2 (1902:MAY/JUNE)"' do
      expect(g.parse_ec('V. 99:2 (1902:MAY/JUNE)')['start_month']).to eq('May')
      expect(g.parse_ec('V. 84 (1898:JULY/SEPT. )')['end_month']).to eq('September')
      expect(g.parse_ec('V. 86 1899:FEB. -MAR.')['end_month']).to eq('March')
      expect(g.parse_ec('V. 86(1899:JAN. -MAR. )')['end_month']).to eq('March')
    end

    it 'parses "V. 155 YR. 1910 MO. JUN NO. 0960243-0963027"' do
      expect(g.parse_ec('V. 155 YR. 1910 MO. JUN NO. 0960243-0963027')['month']).to eq('June')
    end

    it 'parses "V. 125 NO. 5-9 DE 1906"' do
      expect(g.parse_ec('V. 125 NO. 5-9 DE 1906')['month']).to eq('December')
    end

    it 'parses "V. 130:2 1907"' do
      # these look like parts, not numbers'
      expect(g.parse_ec('V. 130:2 1907')['part']).to eq('2')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(g.canonicalize({})).to be_nil
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(g.ocns).to include(1_768_634)
    end
  end
end
