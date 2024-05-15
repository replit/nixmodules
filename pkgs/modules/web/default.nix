{ pkgs, ... }: {
  id = "web";
  name = "Web Tools";
  description = ''
    Web development tools. Includes VS Code HTML language server, VS Code CSS language server, TypeScript language server.
  '';

  imports = [
    (import ../typescript-language-server {
      nodepkgs = pkgs.nodePackages;
    })
  ];

  replit.dev.languageServers.html = {
    name = "HTML Language Server";
    language = "html";
    extensions = [ ".html" ];

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

  replit.dev.languageServers.css = {
    name = "CSS Language Server";
    language = "css";
    extensions = [ ".css" ".less" ".scss" ];

    start = "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-css-language-server --stdio";

    initializationOptions = {
      provideFormatter = true;
    };

    configuration =
      let
        config = {
          completion = {
            triggerPropertyValueCompletion = true;
            completePropertyWithSemicolon = true;
          };

          hover = {
            documentation = true;
            references = true;
          };

          # Configure linting
          # ignore = don't show any warning or error
          # warning = show yellow underline
          # error = show red underline
          lint = {
            # Invalid number of parameters
            argumentsInColorFunction = "error";
            # Do not use width or height when using padding or border
            boxModel = "ignore";
            # When using a vendor-specific prefix make sure to also include all other vendor-specific properties
            compatibleVendorPrefixes = "ignore";
            # Do not use duplicate style definitions
            duplicateProperties = "warning";
            # Do not use empty rulesets
            emptyRules = "warning";
            # Avoid using 'float'. Floats lead to fragile CSS that is easy to break if one aspect of the layout changes.
            float = "ignore";
            # @font-face rule must define 'src' and 'font-family' properties
            fontFaceProperties = "warning";
            # Hex colors must consist of three, four, six, or eight hex digits
            hexColorLength = "error";
            # Selectors should not contain IDs because these rules are too tightly coupled with the HTML
            idSelector = "ignore";
            # IE hacks are only necessary when supporting IE7 and below
            ieHack = "ignore";
            # Avoid using !important. It is an indication that the specificity of the entire CSS has gotten out of control and needs to be refactored.
            important = "ignore";
            # Import statements do not load in parallel
            importStatement = "ignore";
            # Property is ignored due to the display
            propertyIgnoredDueToDisplay = "warning";
            # The universal selector (*) is known to be slow
            universalSelector = "ignore";
            # Unkown at-rule
            unknownAtRules = "warning";
            # Unknown properties
            unknownProperties = "warning";
            # Unknown vendor specific properties
            unknownVendorSpecificProperties = "ignore";
            # Add some properties that the linter doesn't know about
            validProperties = [ ];
            # When using a vendor-specific prefix also include the standard property
            vendorPrefix = "warning";
            # No unit for zero needed
            zeroUnits = "ignore";
          };

          trace.server = "off";
        };
      in
      {
        css = config;
        scss = config;
        less = config;
      };
  };
}
