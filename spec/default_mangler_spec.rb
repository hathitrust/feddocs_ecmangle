# frozen_string_literal: true

require 'ecmangle'
require 'yaml'

DM = ECMangle::DefaultMangler
require 'custom_manglers/agricultural_statistics'
AS = ECMangle::AgriculturalStatistics

describe 'initialize' do
  let(:bulletin) do
    DM.new(YAML.load_file(
             File.dirname(__FILE__) +
              '/custom_manglers/dummy_config.yml'
           ))
  end

  it 'takes title from parsed YAML' do
    expect(DM.new.title).to eq('Default Mangler')
    expect(bulletin.title).to eq('Bulletin of the United States Bureau of Labor Statistics')
  end

  it 'takes ocns from parsed YAML' do
    expect(bulletin.ocns).to eq([1_714_756, 604_255_105])
  end

  it 'takes sudoc stems from parsed YAML' do
    expect(bulletin.sudoc_stems).to eq([])
  end

  it 'doesn\'t overwrite tokens' do
    expect(bulletin.tokens).to include(:n)
  end

  it 'takes new tokens from YAML' do
    expect(bulletin.tokens.keys).to include(:dummy_token)
    # but doesn't mess up future manglers
    expect(DM.new.tokens.keys).not_to include(:dummy_token)
    # or other manglers
    expect(AS.new.tokens.keys).not_to include(:dummy_token)
  end

  it 'takes new patterns from YAML' do
    expect(bulletin.patterns).to include(/plain text/)
    expect(bulletin.patterns).to include(/^#{bulletin.tokens[:y]}$/ix)
  end

  it 'takes patterns with references to tokens' do
    expect(bulletin.patterns).to include(/^not\s#{bulletin.tokens[:y]}$/ix)
    expect(bulletin.patterns).to include(/^not\sdummy$/)
  end

  it 'takes canonical order from YAML' do
    expect(bulletin.t_order[1]).to eq('volume')
  end
end

describe 'tokens' do
  it 'matches "OCT."' do
    expect(/#{DM.new.tokens[:m]}/xi.match('OCT.')['month']).to eq('OCT.')
  end

  it 'matches "NO. 12-13"' do
    expect(/#{DM.new.tokens[:ns]}/xi.match('NO. 12-13')['start_number']).to eq('12')
  end

  it 'matches "SUP."' do
    expect(/#{DM.new.tokens[:sup]}/xi.match('SUP.')['supplement']).to eq('SUP.')
  end

  it 'y matches "YR. 1993"' do
    expect(/#{DM.new.tokens[:y]}/xi.match('YR. 1993')['year']).to eq('1993')
  end
end

describe 'parse_ec' do
  it 'parses V. 2' do
    expect(DM.new.parse_ec('V. 2')['volume']).to eq('2')
  end

  it 'parses V. 127(1954)' do
    parsed = DM.new.parse_ec('V. 127(1954)')
    expect(parsed['volume']).to eq('127')
  end

  it 'parses (1984)' do
    expect(DM.new.parse_ec('(1984)')['year']).to eq('1984')
  end

  it 'parses "Year:1977, Volume:50, Number:23"' do
    expect(DM.new.parse_ec('Year:1977, Volume:50, Number:23')['number']).to eq('23')
  end

  it 'parses "1993:NO. 1"' do
    expect(DM.new.parse_ec('1993:NO. 1')['year']).to eq('1993')
  end
end

describe 'register_mangler' do
  it 'registers itself as the default mangler' do
    dsh = DM.new
    expect(ECMangle.default_ec_mangler).to be(dsh)
  end
end
