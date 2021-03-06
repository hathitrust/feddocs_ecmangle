# frozen_string_literal: false

require 'json'
require 'custom_manglers/foreign_relations'
FR = ECMangle::ForeignRelations

describe 'ForeignRelations' do
  let(:src) { FR.new }

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/foreign_relations_enumchrons.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        l = line.clone
        ec = src.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts "no match: '#{l}' : '#{line}'"
        else
          matches += 1
        end
      end

      puts "FR Reports Record match: #{matches}"
      puts "FR Reports Record no match: #{misses}"
      expect(matches).to eq(4626)
      # expect(matches).to eq(matches+misses)
    end

    it 'parses V. 4 1939' do
      expect(src.parse_ec('V. 4 1939')['volume']).to eq('4')
    end

    it "parses '1969-76:V. 14'" do
      expect(src.parse_ec('1969-76:V. 14')['volume']).to eq('14')
    end

    it "parses '948/V. 1:PT. 1'" do
      expect(src.parse_ec('948/V. 1:PT. 1')['year']).to eq('1948')
    end

    it "parses 'V. -54/V. 5/PT. 1'" do
      expect(src.parse_ec('V. -54/V. 5/PT. 1')['year']).to eq('1954')
    end

    it "parses 'V. 10'" do
      expect(src.parse_ec('V. 10')['volume']).to eq('10')
    end

    it "parses 'V. -54/V. 5/PT. 1'" do
      expect(src.parse_ec('V. -54/V. 5/PT. 1')['volume']).to eq('5')
    end

    it 'ignores FICHE' do
      expect(src.parse_ec('1952/54:V. 5:PT. 2:FICHE 6-9')['volume']).to eq('5')
    end

    it "parses '1958-1960'" do
      expect(src.parse_ec('1958-1960')['start_year']).to eq('1958')
    end
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(src.canonicalize({})).to be_nil
    end

    it "canonicalizes 'V. -54/V. 5/PT. 1'" do
      parsed = src.parse_ec('V. -54/V. 5/PT. 1')
      expect(src.canonicalize(parsed)).to eq('Year:1954, Volume:5, Part:1')
    end
  end

  describe 'explode' do
  end

  describe 'sudoc_stem' do
    it 'has a sudoc_stem field' do
      expect(FR.new.sudoc_stems).to eq(['S 1.1:'])
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      # expect(FR.new.ocns).to include(10648533)
    end
  end
end
