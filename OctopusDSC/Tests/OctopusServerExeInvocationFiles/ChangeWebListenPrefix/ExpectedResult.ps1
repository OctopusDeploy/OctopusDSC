return @(
  "configure --console --instance OctopusServer --upgradeCheck True --upgradeCheckWithStatistics False --webListenPrefixes http://localhost:83 --commsListenPort 10935 --webForceSSL False --home C:\Octopus --autoLoginEnabled True --hstsEnabled False --hstsMaxAge 3600",
  "service --stop --console --instance OctopusServer",
  "service --start --console --instance OctopusServer"
)
