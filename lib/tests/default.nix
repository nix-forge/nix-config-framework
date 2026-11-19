{ lib }:
let
  framework = import ../. { inherit lib; };
  generic = framework.mkModuleSet ./fixture/modules/nixos;
  shared = framework.mkSharedModuleSet {
    root = ./fixture/modules/shared;
    class = "nixos";
    args = { };
  };
  policy = framework.mkModuleSet ./policy/group;
  targets = framework.readTargetSpecs {
    root = ./fixture/targets;
    modules.example = "selected";
    args.label = "provided";
  };
  cases = {
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
      expr = framework.mkModuleSet ./policy/collision;
      expectedError.type = "ThrownError";
      expectedError.msg = ".*duplicate generated selector.*";
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
    testDisjoint = {
      expr = framework.disjoint { alpha = 1; } { beta = 2; };
      expected = {
        alpha = 1;
        beta = 2;
      };
    };
    testDisjointCollision = {
      expr = framework.disjoint { alpha = 1; } { alpha = 2; };
      expectedError.type = "ThrownError";
      expectedError.msg = ".*duplicate module selector.*alpha.*";
    };
    testTargetModules = {
      expr = framework.targetModules {
        modules = [ "selected" ];
        localModules = [ "local" ];
      };
      expected = [
        "selected"
        "local"
      ];
    };
    testNixpkgsArgsPrecedence = {
      expr = framework.nixpkgsArgs {
        nixpkgsArgs = {
          config.allowUnfree = true;
        };
        nixpkgs = { };
      };
      expected = {
        config.allowUnfree = true;
      };
    };
    testReadTargetSpecs = {
      expr = {
        names = builtins.attrNames targets;
        inherit (targets.sample)
          name
          folderName
          label
          modules
          ;
        localFiles = map baseNameOf targets.sample.localModules;
      };
      expected = {
        names = [ "sample" ];
        name = "sample";
        folderName = "sample";
        label = "provided";
        modules = [ "selected" ];
        localFiles = [ "settings.nix" ];
      };
    };
    testAggregate = {
      expr = framework.aggregate [
        "first"
        "second"
      ];
      expected = {
        imports = [
          "first"
          "second"
        ];
      };
    };
  };
in
cases
