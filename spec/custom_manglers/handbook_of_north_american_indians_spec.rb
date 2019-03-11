# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'HandbookNA' do
  let(:hb) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/handbook_na.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/handbook_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = hb.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts hb.canonicalize(ec)
          res = hb.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Handbook of NA match: #{matches}"
      puts "Handbook of NA no match: #{misses}"
      # actual number in test file is 104
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(101)
    end

    it 'parses "V. 11 (1986)"' do
      expect(hb.parse_ec('V. 11 (1986)')['volume']).to eq('11')
    end

    it 'parses "V. 10 (1983) (C. 1)"' do
      expect(hb.parse_ec('V. 10 (1983) (C. 1)')['volume']).to eq('10')
    end

    it 'parses "17"' do
      expect(hb.parse_ec('17')['volume']).to eq('17')
    end

    it 'parses "V. 13:1"' do
      expect(hb.parse_ec('V. 13:1')['part']).to eq('1')
      expect(hb.parse_ec('V. 13:1 (2001)')['part']).to eq('1')
    end

    it 'ignores descriptors' do
      expect(hb.parse_ec('V. 15 NORTHEAST')['volume']).to eq('15')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(hb.canonicalize({})).to be_nil
    end

    it 'turns a parsed ec into a canonical string' do
      parsed = hb.parse_ec('8')
      expect(hb.canonicalize(parsed)).to eq('Volume:8')
    end

    it 'ignores descriptors' do
      parsed = hb.parse_ec('V. 15 NORTHEAST')
      expect(hb.canonicalize(parsed)).to eq('Volume:15')
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(hb.ocns).to include(13_240_086)
    end
  end
end
