# waiting for upstream to include our patch: https://github.com/lkl/linux/pull/532 and https://github.com/lkl/linux/pull/534
{ lkl, fetchFromGitHub }:
lkl.overrideAttrs (oldAttrs: {
  src = fetchFromGitHub {
    owner = "numtide";
    repo = "linux-lkl";
    rev = "2cbcbd26044f72e47740588cfa21bf0e7b698262";
    sha256 = "sha256-i7uc69bF84kkS7MahpgJ2EnWZLNah+Ees2oRGMzIee0=";
  };
})
