require_relative "lib/require"

name = ARGV.first
path = File.join($root_dir, "patches", "#{name}_patch.rb")

abort "Unknown patch: #{name}" unless name.present? && File.file?(path)

Object.const_get("#{name.split("_").map(&:capitalize).join}Patch").call
