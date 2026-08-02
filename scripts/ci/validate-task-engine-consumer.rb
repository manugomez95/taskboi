#!/usr/bin/env ruby
# frozen_string_literal: true

require "psych"

EXPECTED_URL = "https://github.com/manugomez95/taskboi.git"
EXPECTED_PATH = "packages/taskboi_task_engine"

def fail_contract(message)
  warn "Task engine consumer contract failed: #{message}"
  exit 1
end

def reject_duplicate_keys!(node)
  if node.is_a?(Psych::Nodes::Mapping)
    seen = {}
    node.children.each_slice(2) do |key, value|
      fail_contract("manifest contains an ambiguous mapping") unless key.is_a?(Psych::Nodes::Scalar)
      fail_contract("manifest contains duplicate mapping keys") if seen[key.value]

      seen[key.value] = true
      reject_duplicate_keys!(value)
    end
  else
    Array(node.children).each { |child| reject_duplicate_keys!(child) } if node.respond_to?(:children)
  end
end

fail_contract("expected one pubspec.yaml filepath") unless ARGV.length == 1
manifest_path = ARGV.fetch(0)
fail_contract("manifest filepath is not a readable file") unless File.file?(manifest_path) && File.readable?(manifest_path)

begin
  source = File.read(manifest_path)
  syntax_tree = Psych.parse_stream(source)
  fail_contract("manifest must contain exactly one YAML document") unless syntax_tree.children.length == 1
  reject_duplicate_keys!(syntax_tree)
  manifest = Psych.safe_load(source, permitted_classes: [], permitted_symbols: [], aliases: false)
rescue Psych::Exception, SystemCallError
  fail_contract("manifest is malformed YAML")
end

fail_contract("manifest root must be a mapping") unless manifest.is_a?(Hash)

dependency_sections = %w[dependencies dev_dependencies dependency_overrides]
locations = dependency_sections.select do |section|
  entries = manifest[section]
  entries.is_a?(Hash) && entries.key?("taskboi_task_engine")
end
fail_contract("dependency must appear exactly once under dependencies") unless locations == ["dependencies"]

dependency = manifest.fetch("dependencies").fetch("taskboi_task_engine")
fail_contract("dependency must use the canonical Git mapping") unless dependency.is_a?(Hash) && dependency.keys == ["git"]

git = dependency["git"]
expected_keys = %w[url ref path]
fail_contract("Git dependency fields must be exact") unless git.is_a?(Hash) && git.keys.sort == expected_keys.sort
fail_contract("Git URL is not canonical") unless git["url"] == EXPECTED_URL
fail_contract("Git ref must be a full commit SHA") unless git["ref"].is_a?(String) && git["ref"].match?(/\A[0-9a-fA-F]{40}\z/)
fail_contract("Git package path is not canonical") unless git["path"] == EXPECTED_PATH

puts "Task engine consumer contract is valid."
