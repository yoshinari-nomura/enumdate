# frozen_string_literal: true

module Enumdate
  module DateEnumerator
    # Base class for DateEnumerator
    class Base
      include DateHelper
      include Enumerable

      def initialize(first_date:, interval: 1, wkst: 1)
        @first_date, @interval, @wkst = first_date, interval, wkst
        @frame_manager = frame_manager.new(first_date, interval, wkst)
        @until_date = nil
      end

      def each
        return enum_for(:each) unless block_given?

        @frame_manager.each do |frame|
          date = occurrence_in_frame(frame)
          next unless date
          next if date < @first_date
          break if @until_date && date > @until_date

          yield date
        end
      end

      # Imprement rewind for Enumrator class
      def rewind
        @frame_manager.rewind
        self
      end

      def forward_to(date)
        @frame_manager.forward_to(date)
      end

      def until(date)
        @until_date = date
      end

      private

      def frame_manager
        raise NotImplementedError
      end

      def occurrence_in_frame(date)
        raise NotImplementedError
      end
    end

    ################################################################
    # Enumerate yealy dates by day like: Apr 4th Tue
    class YearlyByDay < Base
      def initialize(first_date:, month:, nth:, wday:, interval: 1)
        super(first_date: first_date, interval: interval)
        @month, @nth, @wday = month, nth, wday
      end

      private

      def frame_manager
        DateFrame::Yearly
      end

      def occurrence_in_frame(date)
        make_date_by_day(year: date.year, month: @month, nth: @nth, wday: @wday)
      rescue ArgumentError
        nil
      end
    end

    ################################################################
    # Enumerate yealy dates by month-day like: Apr 22
    # s, e = Date.new(2021, 1, 1), Date.new(20100, 12, 31)
    # Enumdate::YearlyByMonthday(start_date: s, end_date: e, month: 4, mday: 22, interval: 2).map(&:to_s)
    # => [2021-04-22, 2023-04-22, ..., 2099-04-22]
    class YearlyByMonthday < Base
      def initialize(first_date:, month:, mday:, interval: 1)
        super(first_date: first_date, interval: interval)
        @month, @mday = month, mday
      end

      private

      def frame_manager
        DateFrame::Yearly
      end

      def occurrence_in_frame(date)
        Date.new(date.year, @month, @mday)
      rescue Date::Error
        nil
      end
    end

    ################################################################
    # Enumerate monthly dates by day like: 4th Tue
    class MonthlyByDay < Base
      def initialize(first_date:, nth:, wday:, interval: 1)
        super(first_date: first_date, interval: interval)
        @nth, @wday = nth, wday
      end

      private

      def frame_manager
        DateFrame::Monthly
      end

      def occurrence_in_frame(date)
        make_date_by_day(year: date.year, month: date.month, nth: @nth, wday: @wday)
      rescue Date::Error
        nil
      end
    end

    ################################################################
    # Enumerate monthly dates by month-day like: 22
    class MonthlyByMonthday < Base
      def initialize(first_date:, mday:, interval: 1)
        super(first_date: first_date, interval: interval)
        @mday = mday
      end

      private

      def frame_manager
        DateFrame::Monthly
      end

      def occurrence_in_frame(date)
        Date.new(date.year, date.month, @mday)
      rescue Date::Error
        nil
      end
    end

    ################################################################
    # Enumerate weekly dates like: Tue
    class Weekly < Base
      def initialize(first_date:, wday:, interval: 1, wkst: 1)
        super(first_date: first_date, interval: interval, wkst: wkst)
        @wday = wday
      end

      private

      def frame_manager
        DateFrame::Weekly
      end

      # Sun Mon Tue Wed Thu Fri Sat Sun Mon Tue ...
      #  0   1   2   3   4   5   6   0   1   2  ...
      def occurrence_in_frame(date)
        bof = date - ((date.wday - @wkst) % 7)
        candidate = bof + (@wday - bof.wday) % 7
        return candidate if date <= candidate

        nil
      end
    end

    ################################################################
    # Enumerate every n days
    class Daily < Base
      def initialize(first_date:, interval: 1)
        super(first_date: first_date, interval: interval)
      end

      private

      def frame_manager
        DateFrame::Daily
      end

      def occurrence_in_frame(date)
        date
      end
    end

    ################################################################
    # Enumerate dates from list.
    class ByDateList
      include Enumerable

      def initialize(date_list: [])
        @date_list = date_list
        @until_date = nil
      end

      def <<(date)
        @date_list << date
      end

      def rewind; end

      def until(date)
        @until_date = date
      end

      def forward_to(date)
        @first_date = date
      end

      def each
        return enum_for(:each) unless block_given?

        @date_list.sort.each do |date|
          next if @fist_date && date < @first_date
          break if @until_date && date > @until_date

          yield date
        end
      end
    end
  end
end
