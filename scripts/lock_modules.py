# lock_modules.py

# This script generates/updates the module registry file `modules.json`.
# modules.json is similar to a lock file used in common packagers in that it fixes
# the exact version of each module. It looks like:

# {
#  "bun-0.5:v1-20230522-ec43fbd": {
#    "commit": "ec43fbd5f1ad8556bb64da7f77ae4af8d9ae6461",
#    "path": "/nix/store/l08f5vl1af9rpzd7kvr0l5gx9v7y8p12-replit-module-bun-0.5"
#  },
#  "c-clang14.0:v1-20230522-ec43fbd": {
#    "commit": "ec43fbd5f1ad8556bb64da7f77ae4af8d9ae6461",
#    "path": "/nix/store/n4vzd9rkpjs72xj9yvlakxh3bardvdki-replit-module-c-clang14.0"
#  },
#  ...
# }

# Keys into the mapping are module registry IDs consisting of `<module ID>:v<version>-<date>-<commit>`
# the values are:
# * commit - the full commit sha
# * path - the output path of the nix derivation when the module ID is build via `nix build .#<module ID>` at the
#          corresponding commit

# It should be run each time when before publishing a PR (but after committing your changes):

# nix develop
# python scripts/lock_modules.py

# CI should run:
#
# python scripts/lock_modules.py -v
#
# to verify someone didn't forget to run this and commit the result before merging a PR.

import subprocess
import json
import os
import re
import argparse

module_registry_id_regex = re.compile(r'^(.+):v([0-9]+)-([0-9]+)-([0-9a-z]+)$')
module_registry_file = 'modules.json'
nix_flags = ['--extra-experimental-features', 'nix-command flakes discard-references']

def get_commit_info():
  output = subprocess.check_output(['git', 'show', '-s', '--format=format:%as|%H'])
  date, commit = str(output, 'UTF-8').split('|')
  return {
    'sha': commit,
    'date': date.replace('-', '')
  }

def is_working_directory_clean():
  output = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'])
  return len(output) == 0

def get_current_modules():
  output = subprocess.check_output(['nix', 'eval', '.#modules', '--json'] + nix_flags)
  return json.loads(output)

def get_module_registry():
  if not os.path.isfile(module_registry_file):
    return {}
  f = open(module_registry_file, 'r')
  fromfile = json.load(f)
  f.close()
  registry = {}
  for module_registry_id, entry in fromfile.items():
    match = module_registry_id_regex.match(module_registry_id)
    module_id, version, date, commit = match.groups()
    if module_id not in registry:
      registry[module_id] = []
    registry[module_id].append({
      'id': module_id,
      'version': int(version),
      'date': date,
      'commit': entry['commit'],
      'path': entry['path']
    })
  return registry

def save_module_registry(registry):
  f = open(module_registry_file, 'w')
  mapping = {}
  for module_id, versions in registry.items():
    for version in versions:
      registry_id = get_module_registry_id(version)
      mapping[registry_id] = {
        'commit': version['commit'],
        'path': version['path']
      }
  json.dump(mapping, f, indent = 2)
  f.close()
  print('Wrote %s' % module_registry_file)

def get_module_registry_id(module):
  return "%s:v%d-%s-%s" % (module['id'], module['version'], module['date'], module['commit'][:7])

def update_module_registry(module_registry):
  commit = get_commit_info()
  modules = get_current_modules()
  changed = False
  for module_id, module_path in modules.items():
    current = None
    if module_id in module_registry:
      # check for module update
      current = module_registry[module_id][-1]
      if current['path'] == module_path:
        continue

    if module_id not in module_registry:
      module_registry[module_id] = []
    
    largest_version = 0
    for m in module_registry[module_id]:
      version = m['version']
      if version > largest_version:
        largest_version = version
    numeric_version = 1 + largest_version
    module = {
      'id': module_id,
      'version': numeric_version,
      'date': commit['date'],
      'commit': commit['sha'],
      'path': module_path
    }
    registry_id = get_module_registry_id(module)
    module_registry[module_id].append(module)
    if current:
      print('%s -> %s' % (get_module_registry_id(current), registry_id))
    else:
      print('%s added' % registry_id)
    changed = True
  return changed
  
def main():
  parser = argparse.ArgumentParser(
    prog='lock_modules',
    description='upserts current modules to %s' % module_registry_file,
  )

  parser.add_argument('-d', '--dirty', action='store_true', help='allow dirty working dir')
  parser.add_argument('-v', '--verify', action='store_true', help='verify %s is up to date' % module_registry_file)

  args = parser.parse_args()

  if not args.dirty and not is_working_directory_clean():
    print('There are uncommitted changes. Exiting.')
    exit(1)

  module_registry = get_module_registry()
  changed = update_module_registry(module_registry)

  if args.verify and changed:
    print('%s is not up to date!!' % module_registry_file)
    exit(1)

  if changed:
    save_module_registry(module_registry)

if __name__ == '__main__':
  main()