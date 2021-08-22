# frozen_string_literal: true

# Enumerator for recurring dates
module Enumdate
  class Error < StandardError; end

  require "date"

  dir = File.expand_path("enumdate", File.dirname(__FILE__))

  autoload :EnumMerger,     "#{dir}/enum_merger.rb"
  autoload :DateEnumerator, "#{dir}/date_enumerator.rb"
  autoload :DateFrame,      "#{dir}/date_frame.rb"
  autoload :DateHelper,     "#{dir}/date_helper.rb"
  autoload :VERSION,        "#{dir}/version.rb"

  class << self
    # @return [DateEnumerator::YearlyByMonthday]
    def yearly_by_monthday(first_date, month: nil, mday: nil, interval: 1)
      month ||= first_date.month
      mday  ||= first_date.mday
      DateEnumerator::YearlyByMonthday.new(
        first_date: first_date,
        month: month,
        mday: mday,
        interval: interval
      )
    end

    # @return [DateEnumerator::YearlyByDay]
    def yearly_by_day(first_date, month: nil, nth: nil, wday: nil, interval: 1)
      month ||= first_date.month
      nth   ||= (first_date.mday + 6) / 7
      wday  ||= first_date.wday
      DateEnumerator::YearlyByDay.new(
        first_date: first_date,
        month: month,
        nth: nth,
        wday: wday,
        interval: interval
      )
    end

    # @return [DateEnumerator::MonthlyByMonthday]
    def monthly_by_monthday(first_date, mday: nil, interval: 1)
      mday ||= first_date.mday
      DateEnumerator::MonthlyByMonthday.new(
        first_date: first_date,
        mday: mday,
        interval: interval
      )
    end

    # @return [DateEnumerator::MonthlyByDay]
    def monthly_by_day(first_date, nth: nil, wday: nil, interval: 1)
      nth  ||= (first_date.mday + 6) / 7
      wday ||= first_date.wday
      DateEnumerator::MonthlyByDay.new(
        first_date: first_date,
        nth: nth,
        wday: wday,
        interval: interval
      )
    end

    # @return [DateEnumerator::Weekly]
    def weekly(first_date, wday: nil, wkst: 1, interval: 1)
      wday ||= first_date.wday
      DateEnumerator::Weekly.new(
        first_date: first_date,
        wday: wday,
        wkst: wkst,
        interval: interval
      )
    end

    # @return [DateEnumerator::Daily]
    def daily(first_date, interval: 1)
      DateEnumerator::Daily.new(
        first_date: first_date,
        interval: interval
      )
    end
  end
end
