{ lib }:
let
  inherit (builtins)
    attrNames
    concatLists
    filter
    isFunction
    listToAttrs
    pathExists
    readDir
    ;
  inherit (lib) hasPrefix hasSuffix removeSuffix;

  visible = name: !(hasPrefix "." name) && name != "archive";
  entries = path: if pathExists path then readDir path else { };
  nixFile = name: type: type == "regular" && hasSuffix ".nix" name && visible name;
  directory = name: type: type == "directory" && visible name;

  uniqueAttrs =
    values:
    let
      names = map (value: value.name) values;
      grouped = lib.groupBy (value: value.name) values;
      duplicate = lib.findFirst (name: builtins.length grouped.${name} > 1) null names;
    in
    if duplicate != null then
      throw "nix-config-framework: duplicate generated selector '${duplicate}'"
    else
      listToAttrs values;

  recursiveNixFiles =
    path:
    concatLists (
      map (
        name:
        let
          type = (entries path).${name};
          child = path + "/${name}";
        in
        if nixFile name type then
          [ child ]
        else if directory name type then
          recursiveNixFiles child
        else
          [ ]
      ) (attrNames (entries path))
    );

  aggregate = paths: { imports = paths; };

  selectorEntries =
    root:
    let
      go =
        path: prefix:
        concatLists (
          map (
            name:
            let
              type = (entries path).${name};
              child = path + "/${name}";
              segment = if nixFile name type then removeSuffix ".nix" name else name;
              key = lib.concatStringsSep "-" (prefix ++ [ segment ]);
            in
            if nixFile name type then
              if name == "default.nix" then
                [ ]
              else
                [
                  {
                    inherit key child;
                    kind = "file";
                  }
                ]
            else if directory name type then
              [
                {
                  inherit key child;
                  kind = "directory";
                }
              ]
              ++ go child (prefix ++ [ name ])
            else
              [ ]
          ) (attrNames (entries path))
        );
    in
    go root [ ];

  mkModuleSet =
    root:
    uniqueAttrs (
      map (entry: {
        name = entry.key;
        value =
          if entry.kind == "file" then
            entry.child
          else if pathExists (entry.child + "/default.nix") then
            entry.child
          else
            aggregate (recursiveNixFiles entry.child);
      }) (selectorEntries root)
    );

  normalizeEnvelope = args: value: if isFunction value then value args else value;

  mkSharedModuleSet =
    {
      root,
      class,
      args,
    }:
    let
      select =
        path:
        let
          envelope = normalizeEnvelope args (import path);
        in
        if builtins.isAttrs envelope && envelope ? ${class} then envelope.${class} else null;
      selectMany = paths: filter (value: value != null) (map select paths);
    in
    uniqueAttrs (
      lib.concatMap (
        entry:
        let
          value =
            if entry.kind == "file" then
              select entry.child
            else if pathExists (entry.child + "/default.nix") then
              select entry.child
            else
              aggregate (selectMany (recursiveNixFiles entry.child));
        in
        if value == null then
          [ ]
        else
          [
            {
              name = entry.key;
              inherit value;
            }
          ]
      ) (selectorEntries root)
    );

  disjoint =
    left: right:
    let
      overlap = filter (name: builtins.hasAttr name left) (attrNames right);
    in
    if overlap != [ ] then
      throw "nix-config-framework: duplicate module selector(s): ${lib.concatStringsSep ", " overlap}"
    else
      left // right;

  readTargetSpecs =
    {
      root,
      modules,
      args,
    }:
    uniqueAttrs (
      lib.concatMap (
        name:
        let
          path = root + "/${name}";
          type = (entries root).${name};
          default = path + "/default.nix";
        in
        if directory name type && pathExists default then
          let
            spec = import default (
              args
              // {
                folderName = name;
                inherit modules;
              }
            );
          in
          [
            {
              inherit name;
              value = spec // {
                inherit name path;
                folderName = name;
                localModules = recursiveNixFiles (path + "/local");
              };
            }
          ]
        else
          [ ]
      ) (attrNames (entries root))
    );

  targetModules = spec: (spec.modules or [ ]) ++ spec.localModules;

  nixpkgsArgs = spec: spec.nixpkgsArgs or spec.nixpkgs or { };
in
{
  inherit
    aggregate
    disjoint
    mkModuleSet
    mkSharedModuleSet
    readTargetSpecs
    recursiveNixFiles
    targetModules
    nixpkgsArgs
    ;
}
