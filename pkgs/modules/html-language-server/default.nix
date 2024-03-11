{ pkgs, configs, ... }:
let cfg = configs.html-language-server;
in
with lib; {
  options = {
    html-language-server.enable = mkEnableOption "HTML Language Server";
  };

  config = mkIf cfg.enable {
    name = "HTML Language Server";
    language = "html";
    extensions = [ ".html" ];
    displayVersion = pkgs.nodePackages.vscode-langservers-extracted.version;

    start = "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-html-language-server --stdio";

    initializationOptions = {
      enable = true;
      provideFormatter = true;
    };

    configuration.html = {
      customData = [ ];
      autoCreateQuotes = true;
      autoClosingTags = true;
      mirrorCursorOnMatchingTag = false;

      completion.attributeDefaultValue = "doublequotes";

      format = {
        enable = true;
        wrapLineLength = 120;
        unformatted = "wbr";
        contentUnformatted = "pre,code,textarea";
        indentInnerHtml = false;
        preserveNewLines = true;
        indentHandlebars = false;
        endWithNewline = false;
        extraLiners = "head, body, /html";
        wrapAttributes = "auto";
        templating = false;
        unformattedContentDelimiter = "";
      };

      suggest.html5 = true;

      validate = {
        scripts = true;
        styles = true;
      };

      hover = {
        documentation = true;
        references = true;
      };

      trace.server = "off";
    };
  };
}
