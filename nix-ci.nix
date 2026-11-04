{
  systems = [ "x86_64-linux" ];
  fail-fast = false;
  fail-on-dangling-dependencies = true;

  dependencies."packages.x86_64-linux.nixmodules-mirror-publish" = [
    "packages.x86_64-linux.nixmodules-mirror-inputs"
  ];

  test.nixmodules-mirror = {
    enable = false;
    package = "packages.x86_64-linux.nixmodules-mirror-publish";
    system = "x86_64-linux";
    branches = [ "main" ];
    in-repo = true;
  };
}
