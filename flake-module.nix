{
  inputs,
  lib,
  config,
  withSystem,
  self,
  ...
}@flakeArgs:
let
  frameworkLib = import ./lib { inherit lib; };
  cfg = config.nixConfigFramework;
  inherit (cfg) root;
  moduleArgs = flakeArgs // {
    inherit root;
  };

  nixosModules = frameworkLib.disjoint (frameworkLib.mkModuleSet (root + "/modules/nixos")) (
    frameworkLib.mkSharedModuleSet {
      args = moduleArgs;
      class = "nixos";
      root = root + "/modules/shared";
    }
  );
  homeModules = frameworkLib.disjoint (frameworkLib.mkModuleSet (root + "/modules/home")) (
    frameworkLib.mkSharedModuleSet {
      args = moduleArgs;
      class = "homeManager";
      root = root + "/modules/shared";
    }
  );
  darwinModules = frameworkLib.disjoint (frameworkLib.mkModuleSet (root + "/modules/darwin")) (
    frameworkLib.mkSharedModuleSet {
      args = moduleArgs;
      class = "darwin";
      root = root + "/modules/shared";
    }
  );

  homes = frameworkLib.readTargetSpecs {
    root = root + "/homes";
    modules = homeModules;
    args = moduleArgs;
  };
  nixosHosts = frameworkLib.readTargetSpecs {
    root = root + "/hosts/nixos";
    modules = nixosModules;
    args = moduleArgs;
  };
  darwinHosts = frameworkLib.readTargetSpecs {
    root = root + "/hosts/darwin";
    modules = darwinModules;
    args = moduleArgs;
  };

  homeId = spec: "${spec.username}@${spec.name}";
  homesById = lib.listToAttrs (
    map (spec: lib.nameValuePair (homeId spec) spec) (lib.attrValues homes)
  );
  resolveHome =
    id: homesById.${id} or (throw "nix-config-framework: host references unknown home '${id}'");

  mkSpecialArgs =
    kind: target: system: name: extra:
    cfg.extraSpecialArgs
    // (cfg.extraSpecialArgsFor { inherit kind target; })
    // {
      inherit inputs self system;
      configName = name;
      targetName = target.name;
    }
    // extra;

  mkHomeModule =
    {
      username,
      home,
      extraModules ? [ ],
    }:
    { lib, ... }: {
      imports = frameworkLib.targetModules home ++ extraModules;
      _module.args =
        cfg.extraSpecialArgs
        // (cfg.extraSpecialArgsFor {
          kind = "home";
          target = home;
        })
        // {
          inherit (home) system;
          configName = homeId home;
          targetName = home.name;
        };
      home = {
        username = lib.mkForce username;
        homeDirectory = lib.mkForce home.homeDirectory;
        uid = lib.mkForce (home.uid or null);
      };
      nix.package = lib.mkForce null;
      programs.home-manager.enable = true;
    };

  hmConnectionModule =
    platform: host: _:
    let
      connections = host.homes or { };
      users = lib.mapAttrs (
        username: connection:
        let
          home = resolveHome connection.config;
        in
        mkHomeModule {
          inherit username home;
          extraModules = connection.extraModules or [ ];
        }
      ) connections;
      declaredUsers = lib.mapAttrs (
        _username: connection:
        let
          home = resolveHome connection.config;
        in
        (connection.user or { }) // { home = lib.mkDefault home.homeDirectory; }
      ) (lib.filterAttrs (_: connection: connection ? user) connections);
      declaredShells = lib.unique (
        lib.filter (shell: shell != null) (
          map (connection: (connection.user or { }).shell or null) (lib.attrValues connections)
        )
      );
    in
    {
      imports = [
        (
          if platform == "nixos" then
            inputs.home-manager.nixosModules.home-manager
          else
            inputs.home-manager.darwinModules.home-manager
        )
      ];
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm.old";
        # Home Manager's extraSpecialArgs are shared by every attached user and
        # take precedence over each user's _module.args. Keep target-specific
        # arguments in mkHomeModule so one host cannot shadow its homes' args.
        extraSpecialArgs =
          cfg.extraSpecialArgs
          // {
            inherit inputs self;
            inherit (host) system;
            configName = host.name;
            targetName = host.name;
          }
          // (host.homeManagerExtraSpecialArgs or { });
        inherit users;
      };
      users.users = declaredUsers;
    }
    // lib.optionalAttrs (platform == "darwin" && declaredShells != [ ]) {
      # nix-darwin only generates /etc/shells for this option. Register each
      # explicitly assigned login shell so macOS accepts the same path used by
      # users.users.<name>.shell.
      environment.shells = declaredShells;
    };

  mkHost =
    platform: builder: host:
    withSystem host.system (
      { inputs', self', ... }:
      builder {
        inherit (host) system;
        specialArgs = mkSpecialArgs platform host host.system host.name (
          {
            inherit
              inputs'
              self'
              homeModules
              homesById
              ;
          }
          // (host.specialArgs or { })
        );
        modules = [
          { networking.hostName = host.hostName or host.hostname or host.name; }
          { nixpkgs = frameworkLib.nixpkgsArgs host; }
        ]
        ++ lib.optionals ((host.homes or { }) != { }) [ (hmConnectionModule platform host) ]
        ++ frameworkLib.targetModules host;
      }
    );

  mkStandaloneHome =
    home:
    withSystem home.system (
      { inputs', self', ... }:
      let
        pkgs = import inputs.nixpkgs ({ inherit (home) system; } // frameworkLib.nixpkgsArgs home);
      in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = mkSpecialArgs "home" home home.system (homeId home) (
          { inherit inputs' self'; } // (home.extraSpecialArgs or { })
        );
        modules = [
          {
            home = {
              username = lib.mkForce home.username;
              homeDirectory = lib.mkForce home.homeDirectory;
              uid = lib.mkForce (home.uid or null);
            };
            programs.home-manager.enable = true;
          }
        ]
        ++ frameworkLib.targetModules home;
      }
    );
in
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  options.nixConfigFramework = {
    root = lib.mkOption {
      type = lib.types.path;
      description = "Repository root containing modules/, hosts/, and homes/.";
    };
    extraSpecialArgs = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Arguments supplied to every generated NixOS, nix-darwin, and Home Manager module.";
    };
    extraSpecialArgsFor = lib.mkOption {
      type = lib.types.raw;
      default = _: { };
      description = "Function receiving { kind, target } and returning target-specific special arguments.";
    };
    inventory = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Resolved target specifications for in-flake extensions.";
    };
  };

  config = {
    systems = lib.mkDefault [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    nixConfigFramework.inventory = {
      modules = {
        nixos = nixosModules;
        homeManager = homeModules;
        darwin = darwinModules;
      };
      homes = homesById;
      hosts = {
        nixos = nixosHosts;
        darwin = darwinHosts;
      };
    };
    flake = {
      modules = {
        nixos = nixosModules;
        homeManager = homeModules;
        darwin = darwinModules;
      };
      inherit nixosModules;
      inherit homeModules;
      inherit darwinModules;
      homeConfigurations = lib.mapAttrs (_: mkStandaloneHome) homesById;
      nixosConfigurations = lib.mapAttrs (_: mkHost "nixos" inputs.nixpkgs.lib.nixosSystem) nixosHosts;
      darwinConfigurations = lib.mapAttrs (
        _: mkHost "darwin" inputs.nix-darwin.lib.darwinSystem
      ) darwinHosts;
    };
  };
}
