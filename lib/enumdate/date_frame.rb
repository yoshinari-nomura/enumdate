# frozen_string_literal: true

module Enumdate
  module DateFrame
    # DateFrame: yearly, monthly, weekly, and daily
    class Base
      include DateHelper
      include Enumerable

      def initialize(first_date, interval = 1, wkst = 1)
        @first_date, @interval, @wkst = first_date, interval, wkst
        rewind
      end

      # SYNOPSIS:
      #   Enumdate::DateFrame::Yearly.new(first_date, interval)
      #   Enumdate::DateFrame::Monthly.new(first_date, interval)
      #   Enumdate::DateFrame::Weekly.new(first_date, interval, wkst)
      #   Enumdate::DateFrame::Daily.new(first_date, interval)
      #
      # Iterate the date in frames of year, month, week, or day,
      # and enumerate the first date of each frame.
      #
      # FIRST_DATE is an arbitrary date of the first frame.
      #
      # Enumdate::DateFrame::Yearly.new(Date.new(2021, 1, 1), 2).lazy.map(&:to_s).take(3).force
      #   => ["2021-01-01", "2023-01-01", "2025-01-01"]
      #
      # Enumdate::DateFrame::Yearly.new(Date.new(2021, 6, 1), 2).lazy.map(&:to_s).take(3).force
      #   => ["2021-01-01", "2023-01-01", "2025-01-01"]
      #
      # Enumdate::DateFrame::Monthly.new(Date.new(2021, 6, 10), 2).lazy.map(&:to_s).take(3).force
      #   => ["2021-06-01", "2021-08-01", "2021-10-01"]
      #
      # Enumdate::DateFrame::Weekly is sensitive to WKST param:
      #
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
      # sun, mon, tue, wed = 0, 1, 2, 3
      #
      # If week start is Sunday:
      # Enumdate::DateFrame::Weekly.new(Date.new(2021, 6, 8), 2, sun).lazy.map(&:to_s).take(3).force
      #   => ["2021-06-06", "2021-06-20", "2021-07-04"]
      #
      # Monday (default):
      # Enumdate::DateFrame::Weekly.new(Date.new(2021, 6, 8), 2, mon).lazy.map(&:to_s).take(3).force
      #   => ["2021-06-07", "2021-06-21", "2021-07-05"]
      #
      # Tuesday:
      # Enumdate::DateFrame::Weekly.new(Date.new(2021, 6, 8), 2, tue).lazy.map(&:to_s).take(3).force
      #   => ["2021-06-08", "2021-06-22", "2021-07-06"]
      #
      # Wednesday:
      # Enumdate::DateFrame::Weekly.new(Date.new(2021, 6, 8), 2, wed).lazy.map(&:to_s).take(3).force
      #   => ["2021-06-02", "2021-06-16", "2021-06-30"]
      #
      # Enumdate::DateFrame::Daily.new(Date.new(2021, 5, 15), 10).lazy.map(&:to_s).take(3).force
      #   => ["2021-05-15", "2021-05-25", "2021-06-04"]
      #
      # `forward_to` method is helpful to jump to some specific date before the iteration.
      # Enumdate::DateFrame::Yearly.new(Date.new(2021, 1, 1), 2).forward_to(Date.new(2100, 1, 1))
      #   .lazy.map(&:to_s).take(3).force
      #   => ["2101-01-01", "2103-01-01", "2105-01-01"]
      #
      # Let's see how it differs from simply changing FIRST_DATE:
      # Enumdate::DateFrame::Yearly.new(Date.new(2100, 1, 1), 2).lazy.map(&:to_s).take(3).force
      #   => ["2100-01-01", "2102-01-01", "2104-01-01"]
      #
      def each
        return enum_for(:each) unless block_given?

        loop do
          yield @current_frame_date
          @current_frame_date = next_frame_start(@current_frame_date)
        end
      end

      # Imprement rewind for Enumrator class
      def rewind
        @current_frame_date = beginning_of_frame(@first_date)
        self
      end

      # Go forward to the frame in which DATE is involved
      def forward_to(date)
        rewind # reset @current_frame_date
        frames = frames_between(@current_frame_date, date)
        cycles = (frames + (@interval - 1)) / @interval
        @current_frame_date = next_frame_start(@current_frame_date, cycles) if cycles.positive?
        self
      end

      private

      def next_frame_start(current_frame_date, cycles = 1)
        raise NotImplementedError
      end

      def beginning_of_frame(date)
        raise NotImplementedError
      end

      def frames_between(date1, date2)
        raise NotImplementedError
      end
    end

    # Dummy date frame
    class Dummy < Base
    end

    # Yearly date frame
    class Yearly < Base
      private

      def next_frame_start(current_frame_date, cycles = 1)
        current_frame_date >> (@interval * 12 * cycles)
      end

      def beginning_of_frame(date)
        beginning_of_year(date)
      end

      def frames_between(date1, date2)
        years_between(date1, date2)
      end
    end

    # Monthly date frame
    class Monthly < Base
      private

      def next_frame_start(current_frame_date, cycles = 1)
        current_frame_date >> (@interval * cycles)
      end

      def beginning_of_frame(date)
        beginning_of_month(date)
      end

      def frames_between(date1, date2)
        months_between(date1, date2)
      end
    end

    # Weekly date frame
    class Weekly < Base
      private

      def next_frame_start(current_frame_date, cycles = 1)
        current_frame_date + (@interval * 7 * cycles)
      end

      def beginning_of_frame(date)
        beginning_of_week(date, @wkst)
      end

      def frames_between(date1, date2)
        (beginning_of_frame(date2) - beginning_of_frame(date1)) / 7
      end
    end

    # Daily date frame
    class Daily < Base
      private

      def next_frame_start(current_frame_date, cycles = 1)
        current_frame_date + (@interval * cycles)
      end

      def beginning_of_frame(date)
        date
      end

      def frames_between(date1, date2)
        date2 - date1
      end
    end
  end
end
