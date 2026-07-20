#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

def fail_check(message)
  warn "Action pin check failed: #{message}"
  exit 1
end

def reject_duplicate_mapping_keys(source, path)
  parameters = Psych.method(:parse_stream).parameters
  stream = if parameters.any? { |kind, name| kind == :key && name == :filename }
             Psych.parse_stream(source, filename: path)
           else
             Psych.parse_stream(source, path)
           end
  visit = lambda do |node|
    if node.is_a?(Psych::Nodes::Mapping)
      seen = {}
      node.children.each_slice(2) do |key, value|
        if key.is_a?(Psych::Nodes::Scalar)
          fail_check("#{path}: duplicate mapping key #{key.value.inspect} at line #{key.start_line + 1}") if seen.key?(key.value)
          seen[key.value] = true
        end
        visit.call(key)
        visit.call(value)
      end
    else
      children = node.children if node.respond_to?(:children)
      children.each { |child| visit.call(child) } if children
    end
  end
  visit.call(stream)
end

def safe_yaml(source, path)
  parameters = Psych.method(:safe_load).parameters
  if parameters.any? { |kind, name| kind == :key && name == :permitted_classes }
    Psych.safe_load(source, permitted_classes: [], permitted_symbols: [], aliases: false, filename: path)
  else
    Psych.safe_load(source, [], [], false, path)
  end
rescue Errno::ENOENT, Errno::EACCES, Psych::Exception => error
  fail_check("#{path}: unable to load valid YAML: #{error.message}")
end

def each_uses(node, path, &block)
  case node
  when Hash
    node.each do |key, value|
      yield(value, path) if key == "uses"
      each_uses(value, path, &block)
    end
  when Array
    node.each { |value| each_uses(value, path, &block) }
  end
end

fail_check("expected at least one workflow file") if ARGV.empty?

ARGV.each do |path|
  source = File.read(path)
  reject_duplicate_mapping_keys(source, path)
  document = safe_yaml(source, path)
  fail_check("#{path}: workflow document must be a mapping") unless document.is_a?(Hash)

  each_uses(document, path) do |reference, source_path|
    fail_check("#{source_path}: uses must be a string") unless reference.is_a?(String)
    next if reference.start_with?("./")

    if reference.start_with?("docker://")
      fail_check("#{source_path}: Docker uses references are not permitted: #{reference}")
    end

    pattern = %r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[^@\s]+)?@[0-9a-fA-F]{40}\z}
    fail_check("#{source_path}: external action is not pinned to a full commit SHA: #{reference}") unless pattern.match?(reference)
  end
rescue Errno::ENOENT, Errno::EACCES, Psych::Exception => error
  fail_check("#{path}: unable to load valid YAML: #{error.message}")
end
