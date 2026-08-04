{ system, targetKind, targetName, ... }:
{
  imports =
    assert system == "aarch64-darwin";
    assert targetName == "fixture";
    [ ];

  home = {
    sessionVariables.FRAMEWORK_TARGET_KIND = targetKind;
    stateVersion = "25.05";
  };
}
