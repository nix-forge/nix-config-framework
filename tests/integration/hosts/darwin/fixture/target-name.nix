{ targetName, ... }:
{
  assertions = [
    {
      assertion = targetName == "fixture";
      message = "nix-config-framework must pass the stable host targetName";
    }
  ];
}
