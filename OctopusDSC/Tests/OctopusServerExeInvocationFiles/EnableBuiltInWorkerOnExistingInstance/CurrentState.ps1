return @{
  Ensure="Present";
  State="Started";
  DownloadUrl="https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.2019.4.0-x64.msi";
  HomeDirectory="C:\Octopus";
  TaskLogsDirectory="C:\Octopus\TaskLogs"
  LogTaskMetrics=$false;
  LogRequestMetrics=$false;
  ListenPort=10935;
  WebListenPrefix="http://localhost:82";
  ForceSSL=$false
  SqlDbConnectionString = "Server=(local);Database=Octopus;Trusted_Connection=True;";
  OctopusBuiltInWorkerCredential = [PSCredential]::Empty;
  OctopusMasterKey = [PSCredential]::Empty;
 }