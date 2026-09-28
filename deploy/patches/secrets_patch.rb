class SecretsPatch < BasePatch
  class << self
    def always
      Cache.if_files_changed(Constants.local_env_path) do
        Cmd.ssh_write(
          Constants.remote_env_path,
          File.read(Constants.local_env_path),
        )
        Cmd.ssh_write(
          Constants.remote_env_prod_path,
          File.read(Constants.local_env_path),
        )
        Cmd.ssh_write(
          File.join(Constants.remote_home_dir, ".env"),
          File.read(Constants.local_env_path),
        )
      end
    end
  end
end
