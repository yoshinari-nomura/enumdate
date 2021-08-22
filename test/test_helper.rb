# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "enumdate"

require "minitest/autorun"

# Monkey patch to Date for testing.
class Date
  # YYYY-MM-DD style: "2021-08-03"
  def ymd
    strftime("%Y-%m-%d")
  end

  # YYYY-MM-DD WWW style: "2021-08-03 Tue"
  def ymdw
    wek = %w[Sun Mon Tue Wed Thu Fri Sat][wday]
    format("%04d-%02d-%02d %s", year, month, mday, wek)
  end

  # YYYY-MM-DD nth WWW style: "2021-08-03 1st Tue"
  def ymdnw
    nth = %w[1st 2nd 3rd 4th 5th][(mday + 6) / 7]
    wek = %w[Sun Mon Tue Wed Thu Fri Sat][wday]
    format("%04d-%02d-%02d %s %s", year, month, mday, nth, wek)
  end
end
