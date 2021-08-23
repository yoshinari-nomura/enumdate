# frozen_string_literal: true

module Enumdate
  # Create new Enumerator merging multiple enumerators.
  #
  # All enumerators should yield objects that respond to `<=>` method.
  # enums = (EnumMerger.new << enum1 << enum2).to_enum
  #
  class EnumMerger
    include Enumerable

    def initialize
      @enumerators = []
    end

    # Implement each for Enumerator class
    def each
      return enum_for(:each) unless block_given?

      previous, has_valid_previous = nil, false
      loop do
        current = next_minimum(@enumerators)
        next if has_valid_previous && current == previous

        yield current
        previous, has_valid_previous = current, true
      end
    end

    # Implement rewind for Enumerator class
    def rewind
      @enumerators.map(&:rewind)
    end

    # Add enumerator
    def <<(enumerator)
      @enumerators << enumerator.to_enum
      self
    end

    private

    # Yield next minimum value
    def next_minimum(enumerators)
      raise StopIteration if enumerators.empty?

      # Could raise StopIteration
      minimum_enumerator(enumerators).next
    end

    def minimum_enumerator(enumerators)
      min_e, min_v = enumerators.first, nil
      enumerators.each do |e|
        v = e.peek
        min_e, min_v = e, v if min_v.nil? || v < min_v
      rescue StopIteration
        # do nothing
      end
      min_e
    end
  end
end
