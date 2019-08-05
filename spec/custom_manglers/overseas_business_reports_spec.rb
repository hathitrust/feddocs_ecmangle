# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'OverseasBusinessReports' do
  let(:obr) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/overseas_business_reports.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/overseas_business_reports_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = obr.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts obr.canonicalize(ec)
          res = obr.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Overseas Business Reports match: #{matches}"
      puts "Overseas Business Reports no match: #{misses}"
      # actual number in test file is 1249
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(1149)
    end

    it 'parses canonical' do
      expect(
        obr.parse_ec(
          'Year:1977, Volume:77, Number:50'
        )['number']
      ).to eq('50')
      expect(
        obr.parse_ec(
          'Year:1977, Number:50'
        )['number']
      ).to eq('50')
    end

    it 'parses "1976:1-21"' do
      expect(
        obr.parse_ec(
          '1976:1-21'
        )['end_number']
      ).to eq('21')
    end

    it 'parses "1980:28"' do
      expect(
        obr.parse_ec(
          '1980:28'
        )['number']
      ).to eq('28')
    end

    it 'parses "1964NO61-80"' do
      expect(
        obr.parse_ec(
          '1964NO61-80'
        )['end_number']
      ).to eq('80')
    end

    it 'parses "NO. 46-85; 1969"' do
      expect(
        obr.parse_ec(
          'NO. 46-85; 1969'
        )['end_number']
      ).to eq('85')
    end
  end

  describe 'tokens' do
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(obr.canonicalize({})).to be_nil
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(obr.ocns).to include(1_792_851)
    end
  end
end
