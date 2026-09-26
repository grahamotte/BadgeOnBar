require "open3"

class TriggerAll
  TASK = '[tasks."manager:trigger"]'

  class << self
    def call
      directories.each { |directory| trigger(directory) }
    end

    def directories
      Dir.children(parent).sort.filter_map do |name|
        path = File.join(parent, name)
        path if triggerable?(path)
      end
    end

    private

    def parent
      File.expand_path("..", Worktree.root)
    end

    def triggerable?(path)
      File.directory?(path) &&
        File.directory?(File.join(path, ".git")) &&
        File.file?(toml(path)) &&
        File.read(toml(path)).include?(TASK)
    end

    def toml(path)
      File.join(path, "mise.toml")
    end

    def trigger(directory)
      stdout, stderr, status = Open3.capture3("mise", "manager:trigger", chdir: directory)
      $stdout.print(stdout)
      $stderr.print(stderr) if stderr.present?
      return if status.success?

      message = stderr.strip
      message = stdout.strip if message.blank?
      raise "mise manager:trigger failed in #{directory}: #{message}"
    end
  end
end
