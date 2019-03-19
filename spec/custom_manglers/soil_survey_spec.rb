# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'SoilSurvey' do
  let(:ss) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/soil_survey.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/soil_survey_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = ss.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts hb.canonicalize(ec)
          res = ss.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Soil Survey match: #{matches}"
      puts "Soil Survey no match: #{misses}"
      # actual number in test file is 5320
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(5003)
    end

    it 'parses KS: SUMNER CO. 1979' do
      expect(ss.parse_ec('KS: SUMNER CO. 1979')['area']).to eq('SUMNER')
      expect(ss.parse_ec('MS: KEMPER COUNTY. 1999')['area']).to eq('KEMPER')
    end

    it 'parses "1942:1"' do
      expect(ss.parse_ec('1942:1')['year']).to eq('1942')
    end

    it 'parses "LA: MONROE PARISH"' do
      expect(ss.parse_ec('LA: MONROE PARISH')['area']).to eq('MONROE')
    end

    it 'parses "UT: CANYONLANDS AREA"' do
      expect(ss.parse_ec('UT: CANYONLANDS AREA')['area']).to eq('CANYONLANDS')
    end

    it 'parses "NO. 19-21"' do
      expect(ss.parse_ec('NO. 19-21')['end_number']).to eq('21')
    end

    it 'parses "NV: CHURCHILL COUNTY AREA 2001 PT. 1"' do
      expect(ss.parse_ec('NV: CHURCHILL COUNTY AREA 2001 PT. 1')['part']).to eq('1')
    end

    it 'parses "WY: GOSHEN CO. NORTHERN PART"' do
      expect(ss.parse_ec('WY: GOSHEN CO. NORTHERN PART')['area_part']).to eq('NORTHERN')
      expect(ss.parse_ec('WY: GOSHEN CO. NORTHERN PART')['area']).to eq('GOSHEN')
      expect(ss.parse_ec('CO: WELD CO. , NORTHERN PART 1982')['area_part']).to eq('NORTHERN')
    end

    it 'parses "1979:103-105"' do
      expect(ss.parse_ec('1979:103-105')['start_number']).to eq('103')
    end

    it 'parses "1954,NO. 1-3"' do
      expect(ss.parse_ec('1954,NO. 1-3')['end_number']).to eq('3')
    end

    it 'parses "1955NO12 1955"' do
      expect(ss.parse_ec('1955NO12 1955')['year']).to eq('1955')
      expect(ss.parse_ec('1955NO1-3 1955')['end_number']).to eq('3')
    end

    it 'parses "1941 NO. 7"' do
      expect(ss.parse_ec('1941 NO. 7')['number']).to eq('7')
      expect(ss.parse_ec('1941,NO. 8')['number']).to eq('8')
    end

    it 'parses "1989:14 (WARREN CO. , NY)"' do
      expect(ss.parse_ec('1989:14 (WARREN CO. , NY)')['area']).to eq('WARREN')
      expect(ss.parse_ec('1985:41 (MOREHOUSE PARISH, LA)')['area']).to eq('MOREHOUSE')
    end

    it 'parses "1925 NO. 11-18"' do
      expect(ss.parse_ec('1925 NO. 11-18')['start_number']).to eq('11')
    end

    it 'parses "1961:23-25 C. 1"' do
      expect(ss.parse_ec('1961:23-25')['end_number']).to eq('25')
      expect(ss.parse_ec('1961:23-25 C. 1')['end_number']).to eq('25')
    end

    it 'parses "1939:16 C. 1"' do
      expect(ss.parse_ec('1939:16 C. 1')['number']).to eq('16')
    end

    it 'parses "UT: BEAVER-COVE FORT AREA"' do
      expect(ss.parse_ec('UT: BEAVER-COVE FORT AREA')['area']).to eq('BEAVER-COVE FORT')
    end

    it 'parses "SC: EDGEFIELD"' do
      expect(ss.parse_ec('SC: EDGEFIELD')['area']).to eq('EDGEFIELD')
    end

    it 'parses its canonical form' do
      expect(ss.parse_ec('State:NY, Area:WARREN, Year:1989, Number:14')['number']).to eq('14')
      expect(ss.parse_ec('State:WY, Area:GOSHEN, Area part:NORTHERN')['area_part']).to eq('NORTHERN')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(ss.canonicalize({})).to be_nil
    end

    it 'turns a parsed ec into a canonical string' do
      parsed = ss.parse_ec('1989:14 (WARREN CO. , NY)')
      expect(ss.canonicalize(parsed)).to eq('State:NY, Area:WARREN, Year:1989, Number:14')
      parsed = ss.parse_ec('WY: GOSHEN CO. NORTHERN PART')
      expect(ss.canonicalize(parsed)).to eq('State:WY, Area:GOSHEN, Area part:NORTHERN')
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(ss.ocns).to include(1_585_684)
    end
  end
end
