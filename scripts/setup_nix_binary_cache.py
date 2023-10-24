#! /usr/bin/env python3
import os
import pathlib

def main():
  auth = get_auth()
  net_rc_path = create_netrc(auth)
  create_signing_key_file(auth)
  create_nix_conf(auth, net_rc_path)

def create_signing_key_file(auth):
  file_contents = "replit-internal-nixcache:%s" % auth["signingKey"]
  signing_key_file_path = os.path.abspath("nix_build_cache_signing_key")
  f = open(signing_key_file_path, "w")
  f.write(file_contents)
  f.close()
  print("Wrote %s" % signing_key_file_path)

def create_nix_conf(auth, netrc_path):
  homedir = os.getenv("HOME")
  nix_conf = "\n".join([
    "substituters = https://cache.nixos.org/ https://nix-build-cache.replit.com/",
    "trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= replit-internal-nixcache:%s" % auth["publicKey"],
    "netrc-file = %s" % netrc_path,
    "experimental-features = nix-command flakes discard-references"
  ])
  nix_conf_dir_path = os.path.abspath("%s/.config/nix/" % homedir)
  pathlib.Path(nix_conf_dir_path).mkdir(parents=True, exist_ok=True)
  nix_conf_path = os.path.abspath("%s/nix.conf" % nix_conf_dir_path)
  f = open(nix_conf_path, "w")
  f.write(nix_conf)
  f.close()
  print("Wrote %s" % nix_conf_path)

def create_netrc(auth):
  netrc = "\n".join([
    "machine nix-build-cache.replit.com",
    "login %s" % auth["login"],
    "password %s" % auth["password"],
    ""
  ])
  netrc_path = os.path.abspath(".netrc")
  f = open(netrc_path, "w")
  f.write(netrc)
  f.close()
  print("Wrote %s" % netrc_path)
  return netrc_path

def get_auth():
  login = os.getenv('NIX_BUILD_CACHE_LOGIN')
  password = os.getenv('NIX_BUILD_CACHE_PASSWORD')
  publicKey = os.getenv('NIX_BUILD_CACHE_PUBLIC_KEY')
  signingKey = os.getenv('NIX_BUILD_CACHE_SIGNING_KEY')
  return {
    'login': login,
    'password': password,
    'publicKey': publicKey,
    'signingKey': signingKey
  }

if __name__ == '__main__':
  main()
