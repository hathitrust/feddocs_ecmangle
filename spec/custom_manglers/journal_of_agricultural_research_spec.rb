# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'JournalAgResearch' do
  let(:jar) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/journal_of_agricultural_research.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/journal_of_ag_research_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = jar.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts jar.canonicalize(ec)
          res = jar.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Jrnal of Ag Research match: #{matches}"
      puts "Jrnal of Ag Research no match: #{misses}"
      # actual number in test file is 890
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(825)
    end

    it 'parses canonical' do
      expect(
        jar.parse_ec(
          'Volume:31, Year:1925, Start month:July, End month:December'
        )['end_month']
      ).to eq('December')
    end

    it 'parses "V. 8 (1917)"' do
      expect(jar.parse_ec('V. 8 (1917)')['volume']).to eq('8')
    end

    it 'parses "V. 66 1943 JAN-JUN"' do
      expect(jar.parse_ec('V. 66 1943 JAN-JUN')['end_month']).to eq('June')
    end

    it 'parses "V. 4:APR. -SEPT. (1915)"' do
      expect(jar.parse_ec('V. 4:APR. -SEPT. (1915)')['end_month']).to eq('September')
      expect(jar.parse_ec('V. 51 (JULY-DEC 1935)')['end_month']).to eq('December')
    end

    it 'parses "V. 48 1934 JA-JE"' do
      expect(jar.parse_ec('V. 48 1934 JA-JE')['end_month']).to eq('June')
    end

    it 'parses "V. 7 1916 OC-DE"' do
      expect(jar.parse_ec('V. 7 1916 OC-DE')['end_month']).to eq('December')
      expect(jar.parse_ec('V. 7 (1916:OCT. /DEC. )')['end_month']).to eq('December')
    end

    it 'parses "V. 651942:JULY-DEC."' do
      # someone screwed up somewhere
      expect(jar.parse_ec('V. 651942:JULY-DEC.')['end_month']).to eq('December')
    end

    it 'parses "V. 70-71 1945"' do
      expect(jar.parse_ec('V. 70-71 1945')['end_volume']).to eq('71')
    end

    it 'parses "V. 3 1914-1915"' do
      expect(jar.parse_ec('V. 3 1914-1915')['end_year']).to eq('1915')
    end

    it 'parses "V23 JA-MR(1923)"' do
      expect(jar.parse_ec('V23 JA-MR(1923)')['year']).to eq('1923')
    end
  end

  describe 'tokens' do
    it 'has a token than matches a weird month' do
      expect(/#{jar.tokens[:m]}/xi.match('JE')['month']).to eq('JE')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(jar.canonicalize({})).to be_nil
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(jar.ocns).to include(1_754_420)
    end
  end
end
