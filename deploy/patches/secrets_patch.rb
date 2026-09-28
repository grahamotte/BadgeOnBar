class SecretsPatch < BasePatch
  class << self
    def always
      Cache.if_files_changed(Constants.local_env_path) do
        Cmd.ssh_write(
          Constants.remote_env_path,
          contents,
        )
        Cmd.ssh_write(
          Constants.remote_env_prod_path,
          contents,
        )
        Cmd.ssh_write(
          File.join(Constants.remote_home_dir, ".env"),
          contents,
        )
      end
    end

    def contents
      "#{File.read(Constants.local_env_path).chomp}\nRAILS_ENV=production\nNODE_ENV=production\n"
    end
  end
end
