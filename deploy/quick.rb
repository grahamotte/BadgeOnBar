require_relative "lib/require"

if Subdomains.droplet?
  GitDeploymentPatch.call
  SecretsPatch.call
  AppPatch.call
end

WebsitePatch.call
