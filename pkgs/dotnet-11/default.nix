{ lib, fetchurl, dotnetCorePackages }:

let
  runtimeVersion = "11.0.0-rc.3.26522.148";
  sdkVersion = "11.0.100-rc.3.26522.148";

  # Override the binary payload as well as its wrapper; source-built SDKs use a VMR.
  overrideDotnet = package: version: url: hash: passthru:
    let
      unwrapped = package.unwrapped.overrideAttrs (old: {
        inherit version;
        src = fetchurl { inherit url hash; };
        # .NET 11's native CLI also loads these libraries dynamically.
        postFixup = old.postFixup + lib.optionalString (old.pname == "dotnet-sdk") ''
          patchelf --add-needed libicui18n.so --add-needed libicuuc.so \
            --add-needed libgssapi_krb5.so --add-needed libssl.so \
            $out/share/dotnet/sdk/*/libdotnet-aot.so
        '';
        passthru = old.passthru // passthru;
        meta = old.meta // {
          platforms = [ "x86_64-linux" ];
          description = "${old.pname} ${version}";
        };
      });
    in
    package.overrideAttrs (old: {
      inherit version;
      src = unwrapped;
      passthru = old.passthru // unwrapped.passthru // { inherit unwrapped; };
      meta = old.meta // {
        platforms = [ "x86_64-linux" ];
        description = "${old.pname} ${version}";
      };
    });

  runtime = overrideDotnet dotnetCorePackages.runtime_10_0-bin runtimeVersion
    "https://builds.dotnet.microsoft.com/dotnet/Runtime/${runtimeVersion}/dotnet-runtime-${runtimeVersion}-linux-x64.tar.gz"
    "sha512-OwWSg/aJ1DOKLe4z4bQz8iGPnXVOJbloIf9oKB6l0PNU1PKEu6ANi1lM8sFmUxWTtTjj+DCKNJym6ETudMA+uw=="
    { };

  aspnetcore = overrideDotnet dotnetCorePackages.aspnetcore_10_0-bin runtimeVersion
    "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/${runtimeVersion}/aspnetcore-runtime-${runtimeVersion}-linux-x64.tar.gz"
    "sha512-TJMZ3K2N1bXq5zTa42MxADp4TkJAE5XPXiSxk5SplVSUodexf/TpMh2TzR2WDKjGbPmoSekNHbfDWlC6VPgmDw=="
    { };

  fetchPackages = lib.mapAttrsToList (pname: hash: dotnetCorePackages.fetchNupkg {
    inherit pname hash;
    version = runtimeVersion;
  });

  # Keep NuGet setup-hook dependencies aligned with the overridden SDK and runtimes.
  commonPackages = fetchPackages {
    "Microsoft.AspNetCore.App.Ref" = "sha512-kHY1S4k2aoUnjJJOvyxSBywlDV0WgHr+CBA2EwqF4hqjd6Ye40NSobIz6OB0auvK5j3ofbDQ9yXT4NgGulw7sA==";
    "Microsoft.AspNetCore.App.Internal.Assets" = "sha512-/WjVHYSSnRAgNi6NV7HlT9Sa6xkZOxWPCzowenyFhVSyK3LBGQNFkkjk4usmQm0Pw2mTZT+DHLPukpR8zYy5OA==";
    "Microsoft.NETCore.DotNetAppHost" = "sha512-JMfztR7v/l3RjQR27R36/icRx1qLOwYVvp6N4N6BzB7S+BY8OY35Nyx2sywWalTz4lRIUQ6gkI58Nl7BrBBOmQ==";
    "Microsoft.NETCore.App.Ref" = "sha512-j8tl8qNGsq8/x+ulBVTXOjRF1hvMpCm82gORO6xe7rFn3MYicZuWdWOD/6gm/6wsmWqdO+P2QxWEgXmqgkNvrQ==";
    "Microsoft.DotNet.ILCompiler" = "sha512-ZLkg9ghP6xBern0790tFqVoF33aForsm4DZEOssxgOYVqKJEDKk5tL3RA5EftRJARqVx+VgyoysowswyZvnPUQ==";
    "Microsoft.NET.ILLink.Tasks" = "sha512-nD0mSN9zKliWuQDKeL+sdOHVd8Y2H9cmknQRxcqFqvjJb0JycVD0xzG1/E1oiUkcqPThrODglG+Y590ouH4C2g==";
  };

  hostPackages = fetchPackages {
    "Microsoft.NETCore.App.Crossgen2.linux-x64" = "sha512-Rhrw9lnZ4O//ZXPI2C8jHIDrHg5Yd4e5Zww9o/ot9rHIF2qE9Hf/+0bYucIEPAq7kDfv/OWkZo94VzC6tHbT0g==";
    "runtime.linux-x64.Microsoft.DotNet.ILCompiler" = "sha512-IKe2pTQj7SHSPXtrhSekhNwa1h32Zkbpi204Q7kFXQAGEWzhA8+SiCkOXVd6zTv2sOsrhVgEtx5yT7DLrB1f2A==";
  };

  targetPackages = {
    linux-x64 = fetchPackages {
      "Microsoft.AspNetCore.App.Runtime.linux-x64" = "sha512-zpnQ46AGuJPn1JhrB12I/IKB+wX3DJ6kTnebnHHcCOcAM2qZMYd4YvqX6LsTCOgVDI0jkFeq1cbyIJPOQ7Hezw==";
      "Microsoft.NETCore.App.Host.linux-x64" = "sha512-JAsf6hU75ApUzFSHZweMY42Ww99EdEYnrXjoGLjaPUZvBnffYlmo0I2eytznYY0b1MJNGLRnojBXUlj3BWeQbA==";
      "Microsoft.NETCore.App.Runtime.linux-x64" = "sha512-aa5l0dbB04tqv5gZG36jL+isSM9xBxUQAPDEK+QQgkiGmI2RqG9pVUrR/otB5qxjm/0tNCvYTHkqLg3rFEFEhQ==";
      "runtime.linux-x64.Microsoft.NETCore.DotNetAppHost" = "sha512-Pd0oycXZofFW2JtfDiHox/c29Eo30wVG8AvkK3CnkALoUeia2nnVpdT2HRkmh5pAT4yGYR/yYRZ1aAhtQMCByw==";
      "Microsoft.NETCore.App.Runtime.NativeAOT.linux-x64" = "sha512-fS2PEsXyXui20naQgEhEUpKuIxowq6yCHOjRf1pBzTQyxpVFPQZ4lg+jMAATSc9A1MdxYpoHHhn5jdVYvduF+g==";
    };
  };
in
overrideDotnet dotnetCorePackages.sdk_10_0-bin sdkVersion
  "https://builds.dotnet.microsoft.com/dotnet/Sdk/${sdkVersion}/dotnet-sdk-${sdkVersion}-linux-x64.tar.gz"
  "sha512-d+9gNiLwYyzln8YxhxydDsDHQCOZg3xlnq1bb8fqiY9/ZKJjLs3I0zMOYIMHQWo2v/kKTRAXkhBIlnYWe5uA2g=="
{
  inherit runtime aspnetcore targetPackages;
  packages = commonPackages ++ hostPackages ++ targetPackages.linux-x64;
}
