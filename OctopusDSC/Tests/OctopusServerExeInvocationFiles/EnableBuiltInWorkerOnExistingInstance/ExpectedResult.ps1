return @(
  "configure --console --instance OctopusServer --upgradeCheck True --upgradeCheckWithStatistics False --webForceSSL False --webListenPrefixes http://localhost:82 --commsListenPort 10935 --home C:\Octopus --autoLoginEnabled True --hstsEnabled False --hstsMaxAge 3600",
  "admin --console --instance OctopusServer --username Admin --password S3cur3P4ssphraseHere!",
  "license --console --instance OctopusServer --free",
  "builtin-worker --instance OctopusServer --username runasuser --password S4cretPassword!"
)
