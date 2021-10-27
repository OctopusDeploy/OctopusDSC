return @{
  Ensure = "Present";
  State = "Started";
  DownloadUrl = "https://octopus-downloads-staging.s3.amazonaws.com/octopus/Octopus.2021.3.7176-corey-use-octopus-client-netframework-on-win-x64-x64.msi";
  HomeDirectory = "C:\Octopus";
  TaskLogsDirectory = "C:\Octopus\TaskLogs"
  LogTaskMetrics = $false;
  LogRequestMetrics = $false;
  ListenPort = 10935;
  WebListenPrefix = "http://localhost:82";
  ForceSSL = $false
  SqlDbConnectionString = "Server=(local);Database=Octopus;Trusted_Connection=True;";
  OctopusBuiltInWorkerCredential = [PSCredential]::Empty;
  OctopusMasterKey = [PSCredential]::Empty;
 }
