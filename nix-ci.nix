{
  systems = [ "x86_64-linux" ];
  fail-fast = false;

  deploy.nixmodules-mirror = {
    enable = false;
    package = "packages.x86_64-linux.nixmodules-mirror-publish";
    system = "x86_64-linux";
    branches = [ "main" ];
    in-repo = true;
  };
}
