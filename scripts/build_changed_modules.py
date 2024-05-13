# This script test builds the updated modules against an upstream branch for a pull request.

import json
import os
import subprocess
import argparse
import re

nix_store_path_pattern = re.compile(r'/nix/store/([0-9a-z]+)')

# returns a set of module versions based on a map of module ID -> Nix store path
# a module version is a 2-tuple: (module ID, sha from Nix store path)
# example: ('python-3.10', 'f7mgxpvxl4vdkijdamfv94nwciv2laas')
def convert_module_map_to_verisons(module_map):
  versions = set()
  for module_id, path in module_map.items():
    match = nix_store_path_pattern.match(path)
    sha = match[1]
    versions.add((module_id, sha))
  return versions

def get_module_versions():
  args = ['nix', 'eval', '.#modules', '--json']
  print(" ".join(args))
  output = subprocess.check_output(args)
  return convert_module_map_to_verisons(json.loads(str(output, 'UTF-8')))

def build_module(module_id):
  args = ['nix', 'build', '-L', '.#modules."%s"' % module_id, '--print-out-paths']
  print(" ".join(args))
  output = subprocess.check_output(args)
  return str(output, 'UTF-8').strip()

def get_upstream_module_versions(branch):
  args = ['nix', 'eval', 'github:replit/nixmodules/%s#modules' % branch, '--json']
  print(" ".join(args))
  output = subprocess.check_output(args)
  return convert_module_map_to_verisons(json.loads(str(output, 'UTF-8')))

def nix_collect_garbage():
  args = ['nix-collect-garbage']
  print(" ".join(args))
  subprocess.run(args)

def verify_no_existing_modules_removed(upstream_module_versions, current_module_versions):
  upstream_modules = {version[0] for version in upstream_module_versions}
  modules = {version[0] for version in current_module_versions}
  diff = upstream_modules - modules
  assert len(diff) == 0, "module(s) deleted: %r" % diff

def main():
  parser = argparse.ArgumentParser(
    prog='build_changed_modules',
    description='builds the modules that were changed from an upstream branch',
  )

  parser.add_argument('upstream_branch')

  args = parser.parse_args()

  upstream_module_versions = get_upstream_module_versions(args.upstream_branch)
  current_module_versions = get_module_versions()

  verify_no_existing_modules_removed(upstream_module_versions, current_module_versions)

  new_module_versions = current_module_versions - upstream_module_versions
  if len(new_module_versions) == 0:
    print('Nothing changed')
  else:
    print('modules to build:', [version[0] for version in new_module_versions])
  for version in new_module_versions:
    module_id, _ = version
    actual_path = build_module(module_id)
    print('%s ok' % module_id)
    nix_collect_garbage()

if __name__ == '__main__':
  main()
