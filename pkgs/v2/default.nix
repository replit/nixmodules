{ pkgs }:

with pkgs.lib;

let

  allModules = [
    (import ../moduleit/module-definition.nix)
    (import ../modules/bundles/go)
    (import ../modules/compilers/go)
    (import ../modules/languageServers/gopls)
    (import ../modules/formatters/gofmt)
    (import ../modules/bundles/ruby)
    (import ../modules/interpreters/ruby)
    (import ../modules/languageServers/solargraph)
    (import ../modules/packagers/rubygems)
    (import ../modules/bundles/nodejs)
    (import ../modules/interpreters/nodejs)
    (import ../modules/formatters/prettier)
    (import ../modules/languageServers/typescript-language-server)
    (import ../modules/packagers/nodejs-packager)
    (import ../modules/debuggers/node-dap)
    (import ../modules/bundles/bun)
    (import ../modules/interpreters/bun)
    (import ../modules/packagers/bun)
    (import ../modules/bundles/web)
    (import ../modules/languageServers/css-language-server)
    (import ../modules/languageServers/html-language-server)
  ];

  evalModule = module:
    (pkgs.lib.evalModules {
      modules = [module] ++ allModules;
      specialArgs = {
        inherit pkgs;
        pkgs-unstable = pkgs;
        modulesPath = ../modules;
      };
    });

  buildModule = module:
    let evalResult = evalModule module;
    toolchainJson = evalResult.config.replit.buildModule;
    options = builtins.removeAttrs evalResult.options ["_module" "description" "displayVersion" "id" "name" "replit"];
    flatten = options: path:
      foldl' (acc: name:
        let value = options.${name};
        newPath = path ++ [name];
        in
        if hasAttr "_type" value && value._type == "option"
        then
          acc ++ [{
            moduleId = concatStringsSep "." path;
            optionName = name;
            option = value;
          }]
        else
          acc ++ (flatten value newPath)
      ) [] (builtins.attrNames options);
    flattened = flatten options [];
    filtered = filter (config: !(strings.hasPrefix "_" config.optionName)) flattened;
    matters = filter (config: config.option.value != config.option.default) filtered;
    result = map (config:
      let option = config.option;
      type = option.type.functor.name;
      typeSpecific =
        if type == "bool"
        then
          {
            booleanValue = option.value;
          }
        else if type == "enum" || type == "str"
        then
          {
            stringValue = option.value;
          }
        else if type == "listOf"
        then
          {
            stringListValue = option.value;
          }
        else if type == "int"
        then
          {
            integerValue = option.value;
          }
        else {};
        in {
          inherit (config) moduleId optionName;
        } // typeSpecific) matters;
    moduleConfig = { values = result; };
    moduleConfigJson = pkgs.writeText "replit-evaled-module-config" (builtins.toJSON moduleConfig);
    in
    pkgs.linkFarm "module-build" ([
      {
        name = "module.json";
        path = toolchainJson;
      }
      {
        name = "moduleConfig.json";
        path = moduleConfigJson;
      }
    ]);

  buildDotReplit = path:
    let toml = builtins.fromTOML (builtins.readFile path);
    in buildModule toml.moduleConfig or {};

  registry-v2 =
    let eval = (pkgs.lib.evalModules {
      modules = allModules;
      specialArgs = {
        inherit pkgs;
        pkgs-unstable = pkgs;
        modulesPath = builtins.toString ./.;
      };
    });
    options = eval.options;
    filteredOptions = builtins.removeAttrs options ["_module" "description" "displayVersion" "id" "name" "replit"];
    gatherOptions = options:
      let filteredAttrNames = filter (name:
        !(strings.hasPrefix "_" name))
        (builtins.attrNames options);
      in
      foldl' (acc: name:
        let option = options.${name};
        description = option.description;
        type = option.type.functor.name;
        extras =
        if type == "bool"
        then
          {
            booleanType = {
              default = option.default;
            };
          }
        else if type == "enum"
        then
          {
            choiceStringType = {
              default = option.default;
              choices = option.definitions;
            };
          }
        else if type == "listOf"
        then
          {
            stringListType = {
              default = option.default;
            };
          }
        else if type == "str"
        then
          {
            stringType = {
              default = option.default;
            };
          }
        else if type == "int"
        then
          {
            integerType = {
              default = option.default;
            };
          }
        else {};
        retOption = {
            inherit name description;
        } // extras;
        in acc ++ [retOption]
      ) [] filteredAttrNames;
    convertOptions = optionsSet:
      # an enable option marks where a module is
      if (builtins.hasAttr "enable" optionsSet) && (optionsSet.enable._type == "option")
      then
        let
          enable = optionsSet.enable;
          name = enable.moduleName;
          description = enable.moduleDescription;
        in
        {
          inherit name description;
          options = gatherOptions optionsSet;
        }
      else builtins.mapAttrs (
        _: set:
        convertOptions set
      ) optionsSet;
    flatten = optionsSet: path:
      foldl' (acc: name:
        let value = optionsSet.${name};
        newPath = path ++ [name];
        in
        # has name attribute means it's a module
        if hasAttr "name" value
        then
          let newValue = {
            id = concatStringsSep "." newPath;
          } // value;
          in
          acc ++ [newValue]
        else
          acc ++ (flatten value newPath)
      ) [] (builtins.attrNames optionsSet);
    converted = convertOptions filteredOptions;
    flattened = flatten converted [];
    output = {
      modulesV2 = flattened;
    };
    in pkgs.writeText "registry-v2.json" (builtins.toJSON output);



in
{
  examples = {
    go = buildModule ./examples/go.nix;
    ruby = buildModule ./examples/ruby.nix;
    web = buildModule ./examples/web.nix;
    bun = buildModule ./examples/bun.nix;
    nodejs = buildModule ./examples/nodejs.nix;
  };

  inherit buildDotReplit;
}