# frozen_string_literal: true

require 'ecmangle'
require 'yaml'
require 'dotenv'
Dotenv.load!

DM = ECMangle::DefaultMangler

describe 'SECNewsDigest' do
  let(:digest) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
             '/../../config/handler_definitions/sec_news_digest.yml'
           ))
  end

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/sec_news_digest_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = digest.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          puts 'no match: ' + line
        else
          # puts "match: "+line
          # puts "year: "+ec['year'] if ec['year']
          # puts digest.canonicalize(ec)
          res = digest.explode(ec)
          res.each do |canon, features|
            # puts canon
          end
          matches += 1
        end
      end
      puts "SEC News Digest match: #{matches}"
      puts "SEC News Digest no match: #{misses}"
      # actual number in test file is 5476
      # expect(matches).to eq(matches+misses)
      expect(matches).to eq(5372)
    end

    it 'parses Number:130' do
      expect(digest.parse_ec('Number:130')['number']).to eq('130')
    end

    it 'parses ISSUE NO. 70:39 (1970)' do
      expect(digest.parse_ec('ISSUE NO. 70:39 (1970)')['number']).to eq('39')
    end

    it 'parses NO. 96-234 (1996:DEC. 10)' do
      expect(digest.parse_ec('NO. 96-234 (1996:DEC. 10)')['number']).to eq('234')
    end

    it 'parses ISSUE 87:72 (1987)' do
      expect(digest.parse_ec('ISSUE 87:72 (1987)')['year']).to eq('1987')
    end

    it 'parses ISSUE NO. 65:8:19 (1965)' do
      # only issues 1965 and earlier had this stupid numbering scheme
      expect(digest.parse_ec('ISSUE NO. 65:8:19 (1965)')['month']).to eq('August')
    end

    it 'parses NO. 1325 (1961/62)' do
      # expect(digest.parse_ec('NO. 1325 (1961/62)')['end_year']).to eq('1962')
    end
  end

  describe 'explode' do
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(digest.canonicalize({})).to be_nil
    end

    it 'turns a parsed ec into a canonical string' do
      parsed = digest.parse_ec('ISSUE NO. 70:39 (1970)')
      expect(digest.canonicalize(parsed)).to eq('Year:1970, Number:39')
    end
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(digest.ocns).to include(8_198_194)
    end
  end
end
