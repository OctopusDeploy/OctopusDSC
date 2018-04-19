return @{
  Ensure="Present";
  State="Started";
  DownloadUrl="https://octopus.com/downloads/latest/WindowsX64/OctopusServer";
  HomeDirectory="C:\Octopus";
  TaskLogsDirectory="C:\Octopus\TaskLogs"
}