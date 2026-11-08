{
  system,
  targetKind,
  targetName,
  configName,
  ...
}:
{
  home = {
    sessionVariables = {
      FRAMEWORK_CONFIG_NAME = configName;
      FRAMEWORK_TARGET_NAME = targetName;
      FRAMEWORK_SYSTEM = system;
      FRAMEWORK_TARGET_KIND = targetKind;
    };
    stateVersion = "25.05";
  };
}
