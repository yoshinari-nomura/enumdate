# frozen_string_literal: true

require "date"
require_relative "test_helper"

# rubocop:disable Metrics/MethodLength

# Test code
class EnumdateTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Enumdate::VERSION
  end

  def test_date_frame_yearly
    # FIRST_DATE is an arbitrary date of the first frame.
    assert_equal Enumdate::DateFrame::Yearly
                   .new(Date.new(2021, 1, 1), 2)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2021-01-01 2023-01-01 2025-01-01]
    assert_equal Enumdate::DateFrame::Yearly
                   .new(Date.new(2021, 6, 1), 2)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2021-01-01 2023-01-01 2025-01-01]
  end

  def test_date_frame_monthly
    assert_equal Enumdate::DateFrame::Monthly
                   .new(Date.new(2021, 6, 10), 2)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2021-06-01 2021-08-01 2021-10-01]
  end

  def test_date_frame_weekly_is_sensitive_to_wkst
    # 2021-06-08 is Tuesday:
    #
    #      June 2021
    # Su Mo Tu We Th Fr Sa
    # 30 31  1  2  3  4  5
    #  6  7  8  9 10 11 12
    # 13 14 15 16 17 18 19
    # 20 21 22 23 24 25 26
    # 27 28 29 30  1  2  3
    #
    mon, tue, wed, june8 = 1, 2, 3, Date.new(2021, 6, 8)

    # Monday (default):
    assert_equal Enumdate::DateFrame::Weekly
                   .new(june8, 2, mon)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2021-06-07 2021-06-21 2021-07-05]
    # Tuesday:
    assert_equal Enumdate::DateFrame::Weekly
                   .new(june8, 2, tue).lazy.map(&:to_s).take(3).force,
                 %w[2021-06-08 2021-06-22 2021-07-06]
    # Wednesday:
    assert_equal Enumdate::DateFrame::Weekly
                   .new(june8, 2, wed).lazy.map(&:to_s).take(3).force,
                 %w[2021-06-02 2021-06-16 2021-06-30]
  end

  def test_date_frame_daily
    assert_equal Enumdate::DateFrame::Daily
                   .new(Date.new(2021, 5, 15), 10)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2021-05-15 2021-05-25 2021-06-04]
  end

  def test_forward_to_method_jumps_to_specific_date
    # `forward_to` method is helpful to jump to some specific date before the iteration.
    assert_equal Enumdate::DateFrame::Yearly
                   .new(Date.new(2021, 1, 1), 2).forward_to(Date.new(2100, 1, 1))
                   .lazy.map(&:to_s).take(3).force,
                 %w[2101-01-01 2103-01-01 2105-01-01]
    # Let's see how it differs from simply changing FIRST_DATE:
    assert_equal Enumdate::DateFrame::Yearly
                   .new(Date.new(2100, 1, 1), 2)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2100-01-01 2102-01-01 2104-01-01]
  end

  def test_enumerator_yearly_by_day
    # 0:sun, 1:mon, 2:tue, 3:wed, 4:thu, 5:fri, 6:sat
    assert_equal Enumdate::DateEnumerator::YearlyByDay
                   .new(first_date: Date.new(2018, 8, 3), month: 8, nth: 1, wday: 5)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2018-08-03 2019-08-02 2020-08-07]
  end

  def test_enumerator_yearly_by_monthday
    assert_equal Enumdate::DateEnumerator::YearlyByMonthday
                   .new(first_date: Date.new(2018, 8, 5), month: 8, mday: 5)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2018-08-05 2019-08-05 2020-08-05]
  end

  def test_enumerator_monthly_by_day
    assert_equal Enumdate::DateEnumerator::MonthlyByDay
                   .new(first_date: Date.new(2018, 8, 3), nth: 1, wday: 5, interval: 1)
                   .lazy.map(&:to_s).take(3).force,
                 %w[2018-08-03 2018-09-07 2018-10-05]
  end

  def test_enumerator_monthly_by_monthday; end

  # The `first_date` value always counts as the first occurrence,
  # even if the first_date does not match the specified rule.
  # This behavior respects RFC5445 (see DTSTART and RRULE).
  def test_enumerator_weekly_counts_first_date_even_not_match_rrule
    august2 = Date.new(2021, 8, 2) # first date is Monday
    august3 = Date.new(2021, 8, 3)

    assert_equal Enumdate.weekly(august2, wday: 2) # even set condition as Tuesday.
                   .lazy.map(&:ymdw).take(3).force,
                 # first_date should be in occurrences.
                 ["2021-08-02 Mon", "2021-08-03 Tue", "2021-08-10 Tue"]

    # `forward_to` simply clips the out-of-range occurrences.
    assert_equal Enumdate.weekly(august2, wday: 2)
                   .forward_to(august3)
                   .lazy.map(&:ymdw).take(3).force,
                 ["2021-08-03 Tue", "2021-08-10 Tue", "2021-08-17 Tue"]
  end

  def test_enumerator_daily; end

  def test_enumdate_enum_merger
    first = Date.new(2021, 8, 4) # Wednesday
    # Every Monday and Wednesday:
    assert_equal (Enumdate::EnumMerger.new <<
                  Enumdate.weekly(first) <<
                  Enumdate.weekly(first, wday: 1)) # wday: 1 ... Monday
                   .lazy.map(&:ymdw).take(4).force,
                 ["2021-08-04 Wed", "2021-08-09 Mon", "2021-08-11 Wed", "2021-08-16 Mon"]
  end
end

# rubocop:enable Metrics/MethodLength
