# frozen_string_literal: true

require 'json'
require 'custom_manglers/public_papers_of_the_presidents'

PubPape = ECMangle::PublicPapersOfThePresidents

describe 'PublicPapersOfThePresidents' do
  let(:src) { PubPape.new }

  describe 'parse_ec' do
    it 'can parse them all' do
      matches = 0
      misses = 0
      input = File.dirname(__FILE__) + '/data/public_papers_ecs.txt'
      File.open(input, 'r').each do |line|
        line.chomp!
        ec = src.parse_ec(line)
        if ec.nil? || ec.empty?
          misses += 1
          # puts 'no match: ' + line
        else
          res = src.explode(ec)
          matches += 1
        end
      end
      puts "Public Papers match: #{matches}"
      puts "Public Papers no match: #{misses}"
      expect(matches).to eq(1528)
      # expect(matches).to eq(matches+misses)
    end

    it 'parses canonical' do
      expect(src.parse_ec('Year:1960, Book:2')['book']).to eq('2')
    end
  end

  describe 'canonicalize' do
    it "returns nil if ec can't be parsed" do
      expect(src.canonicalize({})).to be_nil
    end

    it 'turns a parsed ec into a canonical string' do
      expect(src.canonicalize(src.parse_ec('1961 BK. 2'))).to eq('Year:1961, Book:2')
    end
  end

  describe 'explode' do
  end

  describe 'ocns' do
    it 'has an ocns field' do
      expect(PubPape.new.ocns).to eq([1_198_154, 47_858_835])
    end
  end
end
