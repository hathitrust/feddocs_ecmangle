# frozen_string_literal: true

require 'ecmangle'
DM = ECMangle::DefaultMangler

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
end

describe 'register_handler' do
  it 'registers itself as the default handler' do
    dsh = DM.new
    expect(ECMangle.default_ec_handler).to be(dsh)
  end
end
