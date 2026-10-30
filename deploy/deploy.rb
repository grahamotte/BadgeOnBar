require_relative "lib/require"

Subdomains.require_droplet!

InstanceCreatePatch.call
DeployUserPatch.call
SwapPatch.call
MetricsPatch.call
UpdatePatch.call
GitDeploymentPatch.call
DependenciesPatch.call
DnsPatch.call
CertPatch.call
SecretsPatch.call
PostgresPatch.call
NginxPatch.call
AppPatch.call
