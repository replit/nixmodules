{
  dapInitializeMessage = {
    command = "initialize";
    type = "request";
    arguments = {
      adapterID = "cppdbg";
      clientID = "replit";
      clientName = "replit.com";
      columnsStartAt1 = true;
      linesStartAt1 = true;
      locale = "en-us";
      pathFormat = "path";
      supportsInvalidatedEvent = true;
      supportsProgressReporting = true;
      supportsRunInTerminalRequest = true;
      supportsVariablePaging = true;
      supportsVariableType = true;
    };
  };

  dapLaunchMessage = program: {
    command = "launch";
    type = "request";
    arguments = {
      MIMode = "gdb";
      arg = [ ];
      cwd = ".";
      environment = [ ];
      externalConsole = false;
      logging = { };
      miDebuggerPath = "gdb";
      name = "gcc - Build and debug active file";
      inherit program;
      request = "launch";
      setupCommands = [
        {
          description = "Enable pretty-printing for gdb";
          ignoreFailures = true;
          text = "-enable-pretty-printing";
        }
      ];
      stopAtEntry = false;
      type = "cppdbg";
    };
  };
}
