{ fetchurl, fetchgit, linkFarm, runCommand, gnutar }: rec {
  offline_cache = linkFarm "offline" packages;
  packages = [
    {
      name = "argparse___argparse_2.0.1.tgz";
      path = fetchurl {
        name = "argparse___argparse_2.0.1.tgz";
        url = "https://registry.yarnpkg.com/argparse/-/argparse-2.0.1.tgz";
        sha512 = "8+9WqebbFzpX9OR+Wa6O29asIogeRMzcGtAINdpMHHyAg10f05aSFVBbcEqGf/PXw1EjAZ+q2/bEBg3DvurK3Q==";
      };
    }
    {
      name = "biwascheme___biwascheme_0.7.5.tgz";
      path = fetchurl {
        name = "biwascheme___biwascheme_0.7.5.tgz";
        url = "https://registry.yarnpkg.com/biwascheme/-/biwascheme-0.7.5.tgz";
        sha512 = "43ZoNvQaQ9vbMbu7Ld0+ff9aqq3fk0jztY0p4fy6UIZUaRAuiK9ulkjtIJG7zRBkD/ZclOGUXbG13SA0jYy2NQ==";
      };
    }
    {
      name = "optparse___optparse_1.0.5.tgz";
      path = fetchurl {
        name = "optparse___optparse_1.0.5.tgz";
        url = "https://registry.yarnpkg.com/optparse/-/optparse-1.0.5.tgz";
        sha1 = "dedallBmEescZbqJAY/wipgeLBY=";
      };
    }
    {
      name = "prettier___prettier_1.19.1.tgz";
      path = fetchurl {
        name = "prettier___prettier_1.19.1.tgz";
        url = "https://registry.yarnpkg.com/prettier/-/prettier-1.19.1.tgz";
        sha512 = "s7PoyDv/II1ObgQunCbB9PdLmUcBZcnWOcxDh7O0N/UwDEsHyqkW+Qh28jW+mVuCdx7gLB0BotYI1Y6uI9iyew==";
      };
    }
    {
      name = "underscore___underscore_1.2.2.tgz";
      path = fetchurl {
        name = "underscore___underscore_1.2.2.tgz";
        url = "https://registry.yarnpkg.com/underscore/-/underscore-1.2.2.tgz";
        sha1 = "dN1A6frOhOck6y7a6UW4rtwjO6M=";
      };
    }
  ];
}
