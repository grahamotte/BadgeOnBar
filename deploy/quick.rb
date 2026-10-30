require_relative "lib/require"

Subdomains.require_droplet!

GitDeploymentPatch.call
SecretsPatch.call
AppPatch.call
