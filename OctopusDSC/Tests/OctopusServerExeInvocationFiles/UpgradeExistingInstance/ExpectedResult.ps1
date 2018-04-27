return @(
  "service --stop --console --instance OctopusServer",
  "configure --console --instance OctopusServer --upgradeCheck True --upgradeCheckWithStatistics False --webForceSSL False --webListenPrefixes http://localhost:82 --commsListenPort 10935 --home C:\Octopus --autoLoginEnabled True --hstsEnabled False --hstsMaxAge 3600",
  "metrics --console --instance OctopusServer --tasks True --webapi True",
  "service --start --console --instance OctopusServer"
)
