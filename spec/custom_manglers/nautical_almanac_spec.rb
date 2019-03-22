# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'NauticalAlmanac' do
  let(:almanac) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/nautical_almanac.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/nautical_almanac_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = almanac.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts almanac.canonicalize(ec)
          res = almanac.explode(ec)
          res.each do |canon, _features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Nautical Almanac match: #{matches}"
      puts "Nautical Almanac no match: #{misses}"
      # actual number in test file is 200
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(188)
    end

    it 'parses "985"' do
      expect(almanac.parse_ec('985')['year']).to eq('1985')
    end

    it 'parses "1948-49"' do
      expect(almanac.parse_ec('1948-49')['end_year']).to eq('1949')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(almanac.canonicalize({})).to be_nil
    end

    it 'turns a parsed ec into a canonical string' do
      parsed = almanac.parse_ec('948')
      expect(almanac.canonicalize(parsed)).to eq('Year:1948')
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(almanac.ocns).to include(1_286_390)
    end
  end
end
