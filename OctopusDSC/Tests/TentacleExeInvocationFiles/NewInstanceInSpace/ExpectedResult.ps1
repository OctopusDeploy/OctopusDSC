return @(
  "create-instance --instance Tentacle --config C:\Octopus\Tentacle\Tentacle.config --console",
  "configure --instance Tentacle --home C:\Octopus --console",
  "configure --instance Tentacle --app C:\Applications --console",
  "new-certificate --instance Tentacle --console",
  "configure --instance Tentacle --port 10935 --console",
  "service --install --instance Tentacle --console --reconfigure --username Admin --password S3cur3P4ssphraseHere!",
  "register-with --instance Tentacle --server http://localhost:81 --name My Tentacle --apiKey API-1234 --force --console --space My Space --comms-style TentaclePassive --publicHostName mytestserver.local --environment dev --environment prod --role web-server"
)
