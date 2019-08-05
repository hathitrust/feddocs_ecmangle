# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

BLS = ECMangle::BLSBulletin

describe 'Bulletin' do
  let(:bulletin) { BLS.new }

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/bls_bulletin_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = bulletin.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts "no match: "+line
        else
          res = bulletin.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "BLS Bulletin match: #{matches}"
      puts "BLS Bulletin no match: #{misses}"
      # actual number in test file is 7074
      expect(matches).to eq(6535)
      # expect(matches).to eq(matches+misses)
    end

    it 'parses Number:130' do
      expect(bulletin.parse_ec('Number:130')['number']).to eq('130')
    end

    it 'parses Number:1116, Part:10' do
      expect(bulletin.parse_ec('Number:1116, Part:10')['part']).to eq('10')
    end

    it 'parses Number:1116, Part:12, Volume:1' do
      expect(bulletin.parse_ec('Number:1116, Part:12, Volume:1')['part']).to eq('12')
    end

    it 'parses Number:1116, Volume:1' do
      expect(bulletin.parse_ec('Number:1116, Volume:1')['volume']).to eq('1')
    end

    it 'parses NO. 960-1 (1949)' do
      expect(bulletin.parse_ec('NO. 960-1 (1949)')['part']).to eq('1')
      expect(bulletin.parse_ec('NO. 960-1 1949')['part']).to eq('1')
    end

    it 'parses NO. 857' do
      expect(bulletin.parse_ec('NO. 857')['number']).to eq('857')
    end

    it 'parses NO. 857 (1987)' do
      expect(bulletin.parse_ec('NO. 857 (1987)')['number']).to eq('857')
    end

    it 'parses NO. 562-565' do
      expect(bulletin.parse_ec('NO. 562-565')['start_number']).to eq('562')
    end

    it 'parses NOS. 561-566 (1932)' do
      expect(bulletin.parse_ec('NOS. 561-566 (1932)')['start_number']).to eq('561')
    end

    it 'parses NO. 908:14 (1949)' do
      expect(bulletin.parse_ec('NO. 908:14 (1949)')['part']).to eq('14')
    end

    it 'parses NO. 609 YR. 1934' do
      expect(bulletin.parse_ec('NO. 609 YR. 1934')['year']).to eq('1934')
    end

    it 'parses NO. 931-945 (1947-1948)' do
      expect(bulletin.parse_ec('NO. 931-945 (1947-1948)')['end_year']).to eq('1948')
    end

    it 'parses NO. 3090,PT. 17-21' do
      expect(bulletin.parse_ec('NO. 3090,PT. 17-21')['end_part']).to eq('21')
    end

    it 'parses V. 932-944' do
      expect(bulletin.parse_ec('V. 932-944')['start_number']).to eq('932')
    end

    it 'parses NO. 1312 PT. 4 1966' do
      expect(bulletin.parse_ec('NO. 1312 PT. 4 1966')['part']).to eq('4')
    end

    it 'parses NO. 2320:V. 2 (1989)' do
      expect(bulletin.parse_ec('NO. 2320:V. 2 (1989)')['volume']).to eq('2')
    end

    it 'parses NO. 247-250,JAN-MAR' do
      expect(bulletin.parse_ec('NO. 247-250,JAN-MAR')['month']).to eq('March')
    end

    it 'parses NO. 1575:31-60 (1968)' do
      expect(bulletin.parse_ec('NO. 1575:31-60 (1968)')['end_part']).to eq('60')
    end

    it 'parses NO. 75-77 MAR-JULY 1908' do
      expect(bulletin.parse_ec('NO. 75-77 MAR-JULY 1908')['month']).to eq('July')
    end

    it 'parses 441 (1927)' do
      expect(bulletin.parse_ec('441 (1927)')['number']).to eq('441')
    end

    it 'parses V. 1502' do
      expect(bulletin.parse_ec('V. 1502')['number']).to eq('1502')
    end

    it 'parses NO. 1312-12 V. 1 1985' do
      expect(bulletin.parse_ec('NO. 1312-12 V. 1 1985')['number']).to eq('1312')
    end

    it 'parses NO. 1312 PT. 12 V. 1 1985' do
      expect(bulletin.parse_ec('NO. 1312 PT. 12 V. 1 1985')['number']).to eq('1312')
    end

    it 'parses NO. 1265 PT. 1-30 1959-1960' do
      expect(bulletin.parse_ec('NO. 1265 PT. 1-30 1959-1960')['start_part']).to eq('1')
    end

    it 'parses NO. 1370:18(1984)' do
      expect(bulletin.parse_ec('NO. 1370:18(1984)')['part']).to eq('18')
    end

    it 'parses NO. 1017-1030 1950-1951' do
      expect(bulletin.parse_ec('NO. 1017-1030 1950-1951')['end_number']).to eq('1030')
    end

    it 'parses NO. 1465:1-30 (1965-66)' do
      expect(bulletin.parse_ec('NO. 1465:1-30 (1965-66)')['start_part']).to eq('1')
    end

    it 'parses V. 1312/8' do
      expect(bulletin.parse_ec('V. 1312/8')['number']).to eq('1312')
    end

    it 'parses C. 1 NO. 642' do
      expect(bulletin.parse_ec('C. 1 NO. 642')['number']).to eq('642')
    end

    it 'parses NO. 1325 (1961/62)' do
      expect(bulletin.parse_ec('NO. 1325 (1961/62)')['end_year']).to eq('1962')
    end
  end

  describe 'explode' do
    it 'expands multi numbers' do
      parsed = bulletin.parse_ec('NOS. 561-566 (1932)')
      expect(bulletin.explode(parsed).count).to eq(6)
    end

    it 'expands multi parts' do
      parsed = bulletin.parse_ec('NO. 1465:1-30 (1965-66)')
      expect(bulletin.explode(parsed).count).to eq(30)
    end
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(bulletin.canonicalize({})).to be_nil
    end

    it 'turns a parsed ec into a canonical string' do
      parsed = bulletin.parse_ec('NO. 1465:8 (1965)')
      expect(bulletin.canonicalize(parsed)).to eq('Number:1465, Part:8')
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(bulletin.ocns).to include(1_714_756)
    end
  end
end
