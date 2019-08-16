# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'UnitedStatesExportsOfDomesticAndForeignMerchandise' do
  let(:daf) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/mangler_definitions/united_states_exports_of_domestic_and_foreign_merchandise.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/united_states_exports_of_domestic_and_foreign_merchandise_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = daf.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts daf.canonicalize(ec)
          res = daf.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "Overseas Business Reports match: #{matches}"
      puts "Overseas Business Reports no match: #{misses}"
      # actual number in test file is 1943
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(1685)
    end

    it 'parses "SEC. E 1945:AUG."' do
      expect(daf.parse_ec('SEC. E 1945:AUG.')['section']).to eq('E')
    end

    it 'parses "SECT. H(1946:APR. )"' do
      expect(daf.parse_ec('SECT. H(1946:APR. )')['section']).to eq('H')
    end

    it 'parses "1958:PT. 1 B"' do
      expect(daf.parse_ec('1958:PT. 1 B')['part']).to eq('1 B')
    end

    it 'parses "PT. II 1959:SEPT."' do
      expect(daf.parse_ec('PT. II 1959:SEPT.')['month']).to eq('September')
      expect(daf.parse_ec('PT. IL 1956:FEB.')['month']).to eq('February')
    end

    it 'parses "1968 C. 1"' do
      expect(daf.parse_ec('1968 C. 1')['year']).to eq('1968')
    end

    it 'parses "3. 164:410/SEC. D/OCT. 1945"' do
      expect(daf.parse_ec('3. 164:410/SEC. D/OCT. 1945')['section']).to eq('D')
      expect(daf.parse_ec('3. 164:410/SEC. H/1947')['section']).to eq('H')
    end

    it 'parses "3. 164:410/PT. 2/JUNE 1951"' do
      expect(daf.parse_ec('3. 164:410/PT. 2/JUNE 1951')['part']).to eq('2')
    end

    it 'parses "PT. 1(1955:JAN. )-PT. 2(1955:APR. )"' do
      expect(daf.parse_ec('PT. 1(1955:JAN. )-PT. 2(1955:APR. )')['end_part']).to eq('2')
    end

    it 'parses "3. 164:410/PT. 2/962-3"' do
      # SuDoc silliness. The last part is <Year>-<month number>, except when
      # the month number is "-13". That is "Annual". Can't really deal with
      # that as a config at the moment.
      expect(daf.parse_ec('3. 164:410/PT. 2/962-3')['month']).to eq('March')
      expect(daf.parse_ec('3. 164:410/PT. 2/962-3')['year']).to eq('1962')
      expect(daf.parse_ec('3. 164:410/963-1')['year']).to eq('1963')
      expect(daf.parse_ec('3. 164:410/PT. 2/962-13')['month']).to eq('Annual')
    end

    it 'parses "956-13/PT. 2"' do
      expect(daf.parse_ec('956-13/PT. 2')['month']).to eq('Annual')
    end

    it 'parses "1960/PT. 2/1-7"' do
      expect(daf.parse_ec('1960/PT. 2/1-7')['end_month']).to eq('July')
    end

    it 'parses "1958 AUG-DEC PT. 2"' do
      expect(daf.parse_ec('1958 AUG-DEC PT. 2')['end_month']).to eq('December')
    end

    it 'parses "1960:NOV. -1960"' do
      expect(daf.parse_ec('1960:NOV. -1960')['year']).to eq('1960')
    end

    it 'parses "1946(A)"' do
      expect(daf.parse_ec('1946(A)')['section']).to eq('A')
    end

    it 'parses "1950(PT. 2)"' do
      expect(daf.parse_ec('1950(PT. 2)')['part']).to eq('2')
    end

    it 'parses "PT. 1-2(1954:ANNU. )"' do
      expect(daf.parse_ec('PT. 1-2(1954:ANNU. )')['start_part']).to eq('1')
    end
  end

  describe 'tokens' do
    it 'matches "SEC. E"' do
      expect(/#{daf.tokens[:sec]}/xi.match('SEC. E')['section']).to eq('E')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(daf.canonicalize({})).to be_nil
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(daf.ocns).to include(7_592_910)
    end
  end
end
