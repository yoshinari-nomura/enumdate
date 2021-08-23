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
        @duration_begin = first_date
        @duration_until = nil
      end

      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def each
        return enum_for(:each) unless block_given?

        # ~first_date~ value always counts as the first occurrence
        # even if it does not match the specified rule.
        # cf. DTSTART vs RRULE in RFC5445.
        yield @first_date if between_duration?(@first_date)

        @frame_manager.each do |frame|
          # Avoid infinite loops even if the rule emits no occurrences
          # such as "31st April in every year".
          # (Every ~occurrence_in_frame(frame)~ returns nil)
          break if @duration_until && @duration_until < frame

          # In some cases, ~occurrence_in_frame~ returns nil.
          # For example, a recurrence that returns 31st of each month
          # will return nil for short months such as April and June.
          next unless (date = occurrence_in_frame(frame))

          break if @duration_until && @duration_until < date

          # ~occurrence_in_frame~ may return a date earlier than
          # ~first_date~ in the first iteration.  This is because
          # ~first_date~ does not necessarily follow the repetition
          # rule.  For example, if the rule is "every August 1st" and
          # ~first_date~ is August 15th, The first occurrence calculated
          # by the rule returns "August 1st", which is earlier than
          # August 15th. In this context, ~@duration_begin~ is the matter.
          next if date < @duration_begin

          # Ignore ~first_date~ not to yield twice.
          next if date == @first_date

          yield date
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Set the new beginning of duration for the recurrence rule.
      #
      # It also controls the underlying frame manager.  Since the
      # frame manager is enough smart to avoid unnecessary repetition,
      # there is no problem in setting the date hundred years later.
      #
      # Note that the meaning of calling ~forward_to~ is different
      # from that of setting the ~first_date~ parameter on creation.
      # For example, if a yearly event has *two-years* ~interval~:
      #
      # 1) if first_date is 2021-08-01 and forward_to 2022-08-01,
      #      it will create [2021-08-01 2023-08-01 ...]
      #
      # 2) if first_date is 2022-08-01,
      #      it will create [2022-08-01 2024-08-01 ...]
      #
      def forward_to(date)
        @frame_manager.forward_to(date)
        @duration_begin = date
        self
      end

      # Implement rewind for Enumerator class
      def rewind
        @frame_manager.rewind
        self
      end

      # Set the new end of duration for the recurrence rule.
      def until(date)
        @duration_until = date
        self
      end

      private

      def between_duration?(date)
        (!@duration_begin || @duration_begin <= date) &&
          (!@duration_until || date <= @duration_until)
      end

      def frame_manager
        raise NotImplementedError
      end

      def occurrence_in_frame(date)
        raise NotImplementedError
      end
    end

    ################################################################
    # Enumerate yearly dates by day like: Apr 4th Tue
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
    # Enumerate yearly dates by month-day like: Apr 22
    # s, e = Date.new(2021, 1, 1), Date.new(20100, 12, 31)
    # Enumdate::YearlyByMonthday(start_date: s, end_date: e, month: 4, mday: 22, interval: 2).map(&:to_s)
    # : => [2021-04-22, 2023-04-22, ..., 2099-04-22]
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
        @duration_until = nil
      end

      def <<(date)
        @date_list << date
      end

      def rewind; end

      def until(date)
        @duration_until = date
      end

      def forward_to(date)
        @first_date = date
      end

      def each
        return enum_for(:each) unless block_given?

        @date_list.sort.each do |date|
          next if @fist_date && date < @first_date
          break if @duration_until && date > @duration_until

          yield date
        end
      end
    end
  end
end
