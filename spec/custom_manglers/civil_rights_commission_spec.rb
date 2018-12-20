# frozen_string_literal: true

require 'ecmangle'
require 'json'
require 'pp'
CRC = ECMangle::CivilRightsCommission

describe 'CRC' do
  let(:src) { CRC.new }

  describe 'parse_ec' do
    it 'does nothing' do
      expect(src.parse_ec('1946, 1948, 1950')).to be_nil
    end
  end

  describe 'explode' do
  end

  describe 'sudoc_stem' do
    it 'has an sudocs field' do
      expect(CRC.new.sudoc_stems).to eq(['CR'])
    end
  end
end
