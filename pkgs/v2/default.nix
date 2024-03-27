{ pkgs }:

with pkgs.lib;

let

  # some are ignored because the are legacy from V1. 'replit' is ignored because it's used
  # as the "output" of the module, not the config
  ignoredConfigs = ["_module" "description" "displayVersion" "id" "name" "replit"];

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

  # Evaluates a set of modules with our special args
  myEvalModules = modules:
    (evalModules {
      inherit modules;
      specialArgs = {
        inherit pkgs;
        pkgs-unstable = pkgs;
        modulesPath = ../modules;
      };
    });

  # does this attrset have an enable option? ie is this a module?
  hasEnableOption = options: hasAttr "enable" options && options.enable._type == "option";

  # given an attrset of nested options, return a list of
  # NixModulesV2RegistryEntry objects in the Replit protobuf protocol
  getModulesFromOptions = options: path:
    foldl' (acc: attrName:
      let
        value = options.${attrName};
      in
        if hasEnableOption value
        then
          let
            enable = value.enable;
            module = {
              id = concatStringsSep "." path;
              name = enable.moduleName;
              description = enable.moduleDescription;
              options = getModuleOptions value;
            };
          in acc ++ [module]
        else
          acc ++ (getModulesFromOptions value (path ++ [attrName]))
    ) [] (attrNames options);

  # given an option, return an attrset containing the type field to use for the
  # NixModuleOption in the Replit protobuf protocol
  getTypeFieldForOption = option:
    let type = option.type.functor.name;
    in if type == "bool"
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

  # convert an attrset of options to a list of NixModuleOptions in the
  # Replit protobuf protocol
  getModuleOptions = options:
    # Filter out internal attributes prefixed with _
    let optionNames = filter (name: !(strings.hasPrefix "_" name)) (attrNames options);
    in
    foldl' (acc: name:
      let
        option = options.${name};
        description = option.description;
        type = option.type.functor.name;
        typeField = getTypeFieldForOption option;
      in acc ++ [({
        inherit name description;
      } // typeField)]
    ) [] optionNames;

  # given an option, return an attrset containing the type-specific
  # `value` field for NixModuleConfigValue in the Replit protobuf protocol
  getTypeSpecificValue = option:
    let type = option.type.functor.name;
    in
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

  # given a nested attrset of options, return a list of
  # NixModuleConfigValue objects in the Replit protobuf protocol
  getConfigValuesFromOptions = options: path:
    foldl' (acc: attrName:
      let
        value = options.${attrName};
        newPath = path ++ [attrName];
      in
        if hasEnableOption value
        then
          let
            moduleId = concatStringsSep "." newPath;
            configValues = map (optionName:
              let option = value.${optionName};
              in {
                inherit moduleId optionName;
              } // (getTypeSpecificValue option)
            ) (attrNames value);
          in
            acc ++ configValues
        else
          acc ++ (getConfigValuesFromOptions value newPath)
    ) [] (attrNames options);

  # given a module evaluation result, return a derivation that builds a JSON file
  # containing the current configuration of the top-level module
  #     containing all config option values for enabled modules.
  buildModuleConfig = evalResult:
    let
      options = removeAttrs evalResult.options ignoredConfigs;
      filterDisabled = options:
        let mapped = mapAttrs (name: value:
          if hasEnableOption value
          then
            if value.enable.value then value else { }
          else
            filterDisabled value
        ) options;
        in
        filterAttrs (name: value: value != { }) mapped;
      enabledOptions = filterDisabled options;
      moduleConfig = { values = getConfigValuesFromOptions enabledOptions []; };
    in pkgs.writeText "replit-module-config" (builtins.toJSON moduleConfig);

  # given a module as an attrset, return a derivation that builds a directory
  # containing files:
  # * module.json - containing the module format used to power the workspace, unchanged from V1
  # * moduleConfig.json - containing the current configuration of the top-level module
  #     containing all config option values for enabled modules.
  buildModule = module:
    let
      evalResult = myEvalModules ([module] ++ allModules);
      moduleJson = evalResult.config.replit.buildModule;
      moduleConfigJson = buildModuleConfig evalResult;
    in
      pkgs.linkFarm "module-build" ([
        {
          name = "module.json";
          path = moduleJson;
        }
        {
          name = "moduleConfig.json";
          path = moduleConfigJson;
        }
      ]);

  # build a module config given a toml file in the .replit format
  # it only considers the `modules` and `moduleConfig` fields
  buildDotReplit = path:
    let toml = builtins.fromTOML (builtins.readFile path);
    in buildModule toml.moduleConfig or {};

  # build the NixModulesGetRegistryResponse object containing the modulesV2 field
  # in the Replit protobuf protocol
  registry =
    let
      options = (myEvalModules allModules).options;
      filteredOptions = removeAttrs options ignoredConfigs;
      modules = getModulesFromOptions filteredOptions [];
      getRegistryResponse = {
        modulesV2 = modules;
      };
    in pkgs.writeText "registry.json" (builtins.toJSON getRegistryResponse);

in
{
  examples = {
    go = buildModule ./examples/go.nix;
    ruby = buildModule ./examples/ruby.nix;
    web = buildModule ./examples/web.nix;
    bun = buildModule ./examples/bun.nix;
    nodejs = buildModule ./examples/nodejs.nix;
  };

  inherit buildDotReplit registry;
}