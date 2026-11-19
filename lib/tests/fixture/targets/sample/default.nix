{
  folderName,
  modules,
  label,
}:
{
  inherit folderName label;
  modules = [ modules.example ];
}
