return @(
    "create-instance --instance Tentacle --config C:\Octopus\Tentacle\Tentacle.config --console",
    "configure --instance Tentacle --home C:\Octopus --console",
    "configure --instance Tentacle --app C:\Applications --console",
    "new-certificate --instance Tentacle --console",
    "configure --instance Tentacle --port 10935 --console",
    "service --install --instance Tentacle --console --reconfigure --username Admin --password S3cur3P4ssphraseHere!",
    "register-worker --instance Tentacle --server http://localhost:81 --name My Worker --force --space My Space --apiKey API-1234 --comms-style TentaclePassive --publicHostName mytestserver.local --workerpool NodeJSWorker"
)
