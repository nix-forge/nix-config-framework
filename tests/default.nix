{ lib }:
let
  framework = import ../lib { inherit lib; };
  generic = framework.mkModuleSet ./fixture/modules/nixos;
  shared = framework.mkSharedModuleSet {
    root = ./fixture/modules/shared;
    class = "nixos";
    args = { };
  };
  callbackOption =
    (import ../flake-module.nix {
      inherit lib;
      inputs = { };
      config = { };
      withSystem = null;
      self = { };
    }).options.nixConfigFramework.extraSpecialArgsFor;
  callbackAccepted =
    definitions:
    (builtins.tryEval (
      (lib.evalModules {
        modules = [
          { options.callback = callbackOption; }
        ]
        ++ map (value: { callback = value; }) definitions;
      }).config.callback
        { }
    )).success;
  policy = framework.mkModuleSet ./policy/group;
  failures = lib.runTests {
    testDefaultPrecedence = {
      expr = (framework.mkModuleSet ./policy/default-root).group;
      expected = ./policy/default-root/group;
    };
    testHiddenAndArchiveFiles = {
      expr = framework.recursiveNixFiles ./policy/group;
      expected = [
        ./policy/group/child.nix
        ./policy/group/default.nix
      ];
    };
    testSelectorCollision = {
      expr = (builtins.tryEval (framework.mkModuleSet ./policy/collision)).success;
      expected = false;
    };
    testPolicySelectors = {
      expr = builtins.attrNames policy;
      expected = [ "child" ];
    };
    testSelectors = {
      expr = builtins.attrNames generic;
      expected = [
        "group"
        "group-alpha"
        "group-beta"
      ];
    };
    testImportOrder = {
      expr = generic.group.imports;
      expected = [
        ./fixture/modules/nixos/group/alpha.nix
        ./fixture/modules/nixos/group/beta.nix
      ];
    };
    testSharedClass = {
      expr = builtins.attrNames shared;
      expected = [ "cross" ];
    };
    testMissingRoot = {
      expr = framework.mkModuleSet ./fixture/missing;
      expected = { };
    };
    testMissingClass = {
      expr = framework.mkSharedModuleSet {
        root = ./fixture/modules/shared;
        class = "absent";
        args = { };
      };
      expected = { };
    };
    testCallback = {
      expr = callbackAccepted [ (_: { }) ];
      expected = true;
    };
    testInvalidCallback = {
      expr = callbackAccepted [ 42 ];
      expected = false;
    };
    testDuplicateCallbacks = {
      expr = callbackAccepted [
        (_: { })
        (_: { })
      ];
      expected = false;
    };
  };
in
if failures == [ ] then true else throw "Framework tests failed: ${builtins.toJSON failures}"
