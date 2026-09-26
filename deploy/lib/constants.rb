class Constants
  class << self
    def local_root = File.dirname(File.dirname(File.dirname(__FILE__)))
    def remote_root = "/var/www/#{domain}"
    def remote_home_dir = "/home/#{deploy_user}"
    def local_git_dir = File.join(local_root, "deploy", "tmp", "#{domain}.git")
    def remote_git_dir = "/home/#{deploy_user}/#{domain}.git"
    def deploy_user = ENV.fetch("DEPLOY_USER")
    def deploy_password = ENV.fetch("DEPLOY_PASSWORD")
    def ssh_key_fingerprint = ENV.fetch("DEPLOY_SSH_KEY_FINGERPRINT")
    def digital_ocean_token = ENV.fetch("DIGITAL_OCEAN_TOKEN")
    def cloudflare_token = ENV.fetch("CLOUDFLARE_TOKEN")
    def domain = ENV.fetch("DOMAIN")
    def instance_region = ENV.fetch("INSTANCE_REGION")
    def instance_size = ENV.fetch("INSTANCE_SIZE")
    def remote_env_path = File.join(remote_root, ".env")
    def remote_env_prod_path = File.join(remote_root, ".env.production")
    def local_env_path = File.join(local_root, ".env.production")
    def db_name = ENV.fetch("DB_NAME")
    def backup_access_key_id = ENV.fetch("BACKUP_ACCESS_KEY_ID")
    def backup_secret_access_key = ENV.fetch("BACKUP_SECRET_ACCESS_KEY")
    def backup_endpoint = ENV.fetch("BACKUP_ENDPOINT")
    def backup_bucket = ENV.fetch("BACKUP_BUCKET")
    def github_repo = ENV.fetch("GITHUB_REPO", "")
    def ssh_key = ENV.fetch("DEPLOY_SSH_KEY")
    def ssh_key_pub = ENV.fetch("DEPLOY_SSH_KEY_PUB")
    def ssh_key_path
      @ssh_key_path ||= begin
        path = File.join(local_root, "deploy", "tmp", "id_rsa")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, ssh_key)
        File.chmod(0600, path)
        path
      end
    end
  end
end
