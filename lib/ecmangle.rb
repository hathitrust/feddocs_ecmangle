# frozen_string_literal: true

require 'forwardable'
require 'default_mangler'
require 'yaml'
# Methods common to EnumChron handling
module ECMangle
  extend Forwardable
  class << self
    attr_accessor :available_ec_manglers
    attr_accessor :default_ec_mangler
    attr_accessor :ocn_manglers # {<ocn> : [<manglers>]}
    attr_accessor :sudoc_manglers # {<sudoc> : [<manglers>]}
  end
  def_delegators :ec_mangler, :parse_ec, :explode, :canonicalize

  @ocn_manglers = Hash.new { |hash, key| hash[key] = [] }
  @sudoc_manglers = Hash.new { |hash, key| hash[key] = [] }
  @available_ec_manglers = {}

  def self.register_mangler(mangler)
    @available_ec_manglers[mangler.title] = mangler
    mangler.ocns.each { |o| @ocn_manglers[o] << mangler }
    mangler.sudoc_stems.each { |s| @sudoc_manglers[s] << mangler }
    @default_ec_mangler = mangler if mangler.sudoc_stems.none? && mangler.ocns.none?
  end

  def ec_mangler
    ECMangle.available_ec_manglers ||= ECMangle.get_available_ec_manglers
    @series ||= series
    @ec_mangler = if @series&.any?
                    ECMangle.available_ec_manglers[@series.first]
                  else
                    ECMangle.default_ec_mangler
                  end
  end

  # given a starting year with 4 digits and an ending year with 2 or 3 digits,
  # figure out the century and millenium
  def self.calc_end_year(start_year, end_year)
    start_year = start_year.to_str
    end_year = end_year.to_str
    if /^\d\d$/.match?(end_year)
      end_year = if end_year.to_i < start_year[2, 2].to_i
                   # crosses century. e.g. 1998-01
                   (start_year[0, 2].to_i + 1).to_s + end_year
                 else
                   start_year[0, 2] + end_year
                 end
    elsif /^\d\d\d$/.match?(end_year)
      end_year = correct_year(end_year)
    end
    end_year
  end

  def remove_dupe_years(ec_string)
    m = ec_string.match(/ (?<first>\d{4}) (?<second>\d{4})$/)
    if !m.nil? && (m['first'] == m['second'])
      ec_string.gsub(/ \d{4}$/, '')
    else
      ec_string
    end
  end
  module_function :remove_dupe_years

  def self.correct_year(year)
    year = year.to_s
    # add a 2; 1699 and 2699 are both wrong, but...
    if year.to_i < 700
      year = '2' + year
    elsif year.to_i < 1000
      year = '1' + year
    end
    year
  end

  # a lot of terrible abbreviations for months
  MONTHS = %w[January February March April May
              June July August September October
              November December].freeze
  def self.lookup_month(mon)
    m_abbrev = mon.chomp('.')
    MONTHS.each do |month|
      return month if /^#{m_abbrev}/i.match?(month) ||
                      m_abbrev.to_i == (MONTHS.index(month) + 1) ||
                      ((m_abbrev.length == 2) &&
                      /^#{m_abbrev[0]}.*#{m_abbrev[1]}/i =~ month)
    end
    nil
  end

  def preprocess(ec_string)
    # fix 3 digit years, this is more restrictive than most series specific
    # work.
    ec_string = '1' + ec_string if ec_string.match?(/^9\d\d$/)
    ec_string.sub(/^C\. [1-2] /, '').sub(/\(\s/, '(').sub(/\s\)/, ')')
  end
  module_function :preprocess

  def fix_months(match_hash)
    match_hash.delete('month') if match_hash['start_month']
    %w[month start_month end_month].each do |capture|
      if match_hash[capture]
        match_hash[capture] = ECMangle.lookup_month(match_hash[capture])
      end
    end
    match_hash
  end
  module_function :fix_months

  def load_context; end

  def record_ocns
    if defined?(ocns) && ocns
      ocns
    else
      []
    end
  end

  def record_sudocs
    if defined?(sudocs) && sudocs
      sudocs
    else
      []
    end
  end

  # Uses ocns and sudocs to identify a series title
  # (and appropriate ultimately mangler)
  def series
    @series ||= []
    record_ocns.each do |ocn|
      @series << ECMangle.ocn_manglers[ocn.to_i].collect(&:title)
    end
    record_sudocs.each do |sudoc|
      ECMangle.sudoc_manglers.each do |stem, manglers|
        if /^#{::Regexp.escape(stem)}/.match?(sudoc)
          @series << manglers.collect(&:title)
        end
      end
    end
    @series.flatten!
    @series.uniq!
    @series
  end

  def self.load_manglers_from_configs
    Dir[File.dirname(__FILE__) +
        '/../config/mangler_definitions/*.yml'].each do |yml|
      ECMangle::DefaultMangler.new(YAML.load_file(yml))
    end
  end

  def self.load_custom_mangler_classes
    Dir[File.dirname(__FILE__) + '/custom_manglers/*.rb'].each { |file| require file }
    constants.each do |c|
      next unless (eval(c.to_s).class == Class) &&
                  (eval(c.to_s).superclass == ECMangle::DefaultMangler)

      eval(c.to_s).new
    end
  end

  def self.get_available_ec_manglers
    ECMangle.load_manglers_from_configs
    ECMangle.load_custom_mangler_classes
    ECMangle.default_ec_mangler = ECMangle::DefaultMangler.new
  end
  get_available_ec_manglers
end
