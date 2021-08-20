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
end
