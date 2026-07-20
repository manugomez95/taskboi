#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "uri"

SOURCE_EXTENSIONS = %w[.ts .tsx .mts .cts .js .jsx .mjs .cjs].freeze
JSON_NAMES = %w[deno.json import_map.json import-map.json].freeze
NUMERIC_IDENTIFIER = /(?:0|[1-9]\d*)/.freeze
PRERELEASE_IDENTIFIER = /(?:0|[1-9]\d*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)/.freeze
SEMVER_VALUE = /#{NUMERIC_IDENTIFIER}\.#{NUMERIC_IDENTIFIER}\.#{NUMERIC_IDENTIFIER}(?:-#{PRERELEASE_IDENTIFIER}(?:\.#{PRERELEASE_IDENTIFIER})*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?/.freeze
SEMVER = /(?:^|@)#{SEMVER_VALUE}(?=\/|[?#]|$)/.freeze
URL = %r{https?://[^\s"'`<>()\[\]{},]+}.freeze
PACKAGE = /\A(?:npm|jsr):(?:@[^\/@]+\/[^@\/]+|[^@\/]+)@#{SEMVER_VALUE}(?:\/[^\s]*)?\z/.freeze
QUOTED_VALUE = /(["'])((?:\\.|(?!\1).)*)\1/m.freeze
TEMPLATE_VALUE = /`((?:\\.|[^`])*)`/m.freeze
IMPORT_ARGUMENT_GAP = /(?:\s|\/\/[^\r\n]*(?:\r?\n|\z)|\/\*.*?\*\/)*/m.freeze

def fail_check(message)
  warn "Remote import check failed: #{message}"
  exit 1
end

def strings_in(value, &block)
  case value
  when Hash
    value.each { |key, child| strings_in(key, &block); strings_in(child, &block) }
  when Array
    value.each { |child| strings_in(child, &block) }
  when String
    yield value
  end
end

def urls_in(source)
  normalized = source.gsub('\\/', '/').gsub(/\\u([0-9a-fA-F]{4})/) { [$1.to_i(16)].pack("U") }
  normalized.scan(URL).uniq
end

def source_imports(source, path)
  patterns = [
    /\bimport\s*(?:\(\s*)?#{QUOTED_VALUE}/m,
    /\b(?:import|export)\s+[^;\n]*?\bfrom\s*#{QUOTED_VALUE}/m
  ]
  quoted_imports = patterns.flat_map do |pattern|
    source.scan(pattern).map do |quote, value|
      if quote == '"'
        JSON.parse(%Q{"#{value}"})
      else
        value.gsub('\\/', '/').gsub("\\'", "'").gsub('\\\\', '\\')
      end
    rescue JSON::ParserError => error
      fail_check("invalid escaped import specifier: #{error.message}")
    end
  end

  template_imports = source.scan(/\bimport\s*\(#{IMPORT_ARGUMENT_GAP}#{TEMPLATE_VALUE}/m).map do |value|
    normalized = value.first.gsub('\\/', '/')
    if normalized.include?('${')
      fail_check("#{path}: dynamic template-literal import contains interpolation")
    end
    next unless normalized.match?(%r{https?://})

    normalized
  end.compact

  (quoted_imports + template_imports).uniq
end

def validate_urls(strings, path)
  strings.each do |value|
    urls_in(value).each do |url|
      begin
        package_path = URI.parse(url).path
      rescue URI::InvalidURIError => error
        fail_check("#{path}: invalid remote import URL: #{error.message}")
      end
      fail_check("#{path}: remote import is not pinned to an exact semantic version: #{url}") unless package_path.match?(SEMVER)
    end
    next unless value.start_with?("npm:", "jsr:")

    fail_check("#{path}: package import is not pinned to an exact semantic version: #{value}") unless value.match?(PACKAGE)
  end
end

def import_map_strings(document, path)
  fail_check("#{path}: JSON document must be an object") unless document.is_a?(Hash)

  values = []
  %w[imports scopes].each do |key|
    next unless document.key?(key)
    fail_check("#{path}: #{key} must be an object") unless document[key].is_a?(Hash)

    strings_in(document[key]) { |value| values << value }
  end
  values
end

fail_check("expected at least one source or JSON file") if ARGV.empty?

ARGV.each do |path|
  basename = File.basename(path)
  extension = File.extname(path)
  source = File.read(path)

  if basename == "deno.jsonc"
    fail_check("#{path}: JSONC is rejected fail-closed; use strict JSON")
  elsif JSON_NAMES.include?(basename)
    begin
      document = JSON.parse(source)
    rescue JSON::ParserError => error
      fail_check("#{path}: invalid JSON: #{error.message}")
    end
    validate_urls(import_map_strings(document, path), path)
  elsif SOURCE_EXTENSIONS.include?(extension)
    validate_urls(source_imports(source, path), path)
  end
rescue Errno::ENOENT, Errno::EACCES => error
  fail_check("#{path}: unable to read input: #{error.message}")
end
