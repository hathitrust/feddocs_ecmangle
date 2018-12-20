# frozen_string_literal: true

require 'ecmangle'
module ECMangle
  # Does nothing. Just filler.
  # Civil Rights Commission "series"
  class CivilRightsCommission < ECMangle::DefaultMangler
    def initialize
      @title = 'Civil Rights Commission'
      @sudoc_stems = ['CR']
      super
    end

    def parse_ec(_ec_string)
      # our match
      m = nil
    end

    # Take a parsed enumchron and expand it into its constituent parts
    # enum_chrons - { <canonical ec string> : {<parsed features>}, }
    def explode(_ec, _src = nil)
      enum_chrons = {}
      enum_chrons
    end

    def canonicalize(_ec)
      nil
    end

    def self.load_context; end
    load_context
  end
end
