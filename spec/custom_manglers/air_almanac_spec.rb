# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'AirAlmanac' do
  let(:aa) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/air_almanac.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/air_almanac_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = aa.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts aa.canonicalize(ec)
          res = aa.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Air Almanac match: #{matches}"
      puts "Air Almanac no match: #{misses}"
      # actual number in test file is 1209
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(1198)
    end

    it 'parses canonical' do
      expect(
        aa.parse_ec(
          'Year:1977, Start Month:January, End Month:June, Number:1, Supplement:Supplement'
        )['end_month']
      ).to eq('June')
    end

    it 'parses "MAY-AUG 1955"' do
      expect(aa.parse_ec('MAY-AUG 1955')['end_month']).to eq('August')
      expect(aa.parse_ec('MAY-AUG. (1955)')['end_month']).to eq('August')
    end

    it 'parses "1966 NO. 1-4"' do
      expect(aa.parse_ec('1966 NO. 1-4')['end_number']).to eq('4')
    end

    it 'parses "1997 1997"' do
      expect(aa.parse_ec('1997 1997')['year']).to eq('1997')
    end

    it 'parses "1956MAY-AUG 1956"' do
      expect(aa.parse_ec('1956MAY-AUG 1956')['end_month']).to eq('August')
    end

    it 'parses "1974:V. 1 C. 1"' do
      expect(aa.parse_ec('1974:V. 1 C. 1')['volume']).to eq('1')
    end

    it 'parses "1978 NO. 1"' do
      expect(aa.parse_ec('1978 NO. 1')['number']).to eq('1')
    end

    it 'parses "1963 JA-AP"' do
      expect(aa.parse_ec('1963 JA-AP')['end_month']).to eq('April')
    end

    it 'parses "1979:JAN. -JUN. = 979/1"' do
      expect(aa.parse_ec('1979:JAN. -JUN. = 979/1')['end_month']).to eq('June')
      expect(aa.parse_ec('1982:JAN. -JUN. = 982')['end_month']).to eq('June')
    end

    it 'parses "977/2"' do
      expect(aa.parse_ec('977/2')['year']).to eq('1977')
      expect(aa.parse_ec('1969:2')['year']).to eq('1969')
    end

    it 'parses "1977 C. 1"' do
      expect(aa.parse_ec('1977 C. 1')['year']).to eq('1977')
    end

    it 'parses "JAN. -JUNE(1979)"' do
      expect(aa.parse_ec('JAN. -JUNE(1979)')['end_month']).to eq('June')
    end

    it 'ignores CDs' do
      expect(aa.parse_ec('1977/CD')['year']).to eq('1977')
    end

    it 'parses "1964,SUP"' do
      expect(aa.parse_ec('1964,SUP')['supplement']).to eq('Supplement')
      expect(aa.parse_ec('1964:SUP.')['supplement']).to eq('Supplement')
      expect(aa.parse_ec('1964SUP 1964')['supplement']).to eq('Supplement')
    end
  end

  describe 'tokens' do
    it 'has a token than matches a weird month' do
      expect(/#{aa.tokens[:m]}/xi.match('JE')['month']).to eq('JE')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(aa.canonicalize({})).to be_nil
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(aa.ocns).to include(2_257_061)
    end
  end
end
