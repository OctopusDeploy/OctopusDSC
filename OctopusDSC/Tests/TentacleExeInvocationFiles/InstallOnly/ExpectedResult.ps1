return @(
    "create-instance --instance Tentacle --config C:\Octopus\Tentacle\Tentacle.config --console",
    "configure --instance Tentacle --home C:\Octopus --console",
    "configure --instance Tentacle --app C:\Applications --console",
    "new-certificate --instance Tentacle --console",
    "configure --instance Tentacle --port 10933 --console",
    "service --install --instance Tentacle --console --reconfigure"
)
