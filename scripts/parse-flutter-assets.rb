#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  require "yaml"
rescue LoadError => error
  warn "Pubspec asset validation failed: Ruby's Psych YAML library is required (#{error.message})."
  exit 1
end

def version_at_least?(actual, minimum)
  actual_parts = actual.split(".").map(&:to_i)
  minimum_parts = minimum.split(".").map(&:to_i)
  width = [actual_parts.length, minimum_parts.length].max
  actual_parts.fill(0, actual_parts.length...width)
  minimum_parts.fill(0, minimum_parts.length...width)
  (actual_parts <=> minimum_parts) >= 0
end

def fail_validation(message)
  warn "Pubspec asset validation failed: #{message}"
  exit 1
end

unless version_at_least?(RUBY_VERSION, "2.6.0")
  fail_validation("Ruby 2.6 or newer is required (found #{RUBY_VERSION})")
end

unless defined?(Psych::VERSION) && version_at_least?(Psych::VERSION, "3.1.0")
  found = defined?(Psych::VERSION) ? Psych::VERSION : "unavailable"
  fail_validation("Psych 3.1 or newer is required (found #{found})")
end

fail_validation("expected exactly one pubspec.yaml path") unless ARGV.length == 1

begin
  source = File.read(ARGV.first)
  safe_load_parameters = Psych.method(:safe_load).parameters
  document = if safe_load_parameters.any? { |kind, name| kind == :key && name == :permitted_classes }
               Psych.safe_load(
                 source,
                 permitted_classes: [],
                 permitted_symbols: [],
                 aliases: false,
                 filename: ARGV.first
               )
             else
               Psych.safe_load(source, [], [], false, ARGV.first)
             end
rescue Errno::ENOENT, Errno::EACCES, Psych::Exception => error
  fail_validation("unable to load valid YAML: #{error.message}")
end

fail_validation("the YAML document must be a mapping") unless document.is_a?(Hash)

flutter = document["flutter"]
exit 0 if flutter.nil?
fail_validation("flutter must be a mapping") unless flutter.is_a?(Hash)

assets = flutter["assets"]
exit 0 if assets.nil?
fail_validation("flutter.assets must be a sequence") unless assets.is_a?(Array)

assets.each do |asset|
  unless asset.is_a?(String) && !asset.empty? && !asset.include?("\0")
    fail_validation("every flutter.assets entry must be a non-empty string")
  end

  STDOUT.write(asset)
  STDOUT.write("\0")
end
