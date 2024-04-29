# This script test builds the updated modules for a pull request branch.

import json
import os
import subprocess
import argparse

module_registry_file = 'modules.json'

def get_modules():
  if not os.path.isfile(module_registry_file):
    return {}
  f = open(module_registry_file, 'r')
  modules = json.load(f)
  f.close()
  return modules

def build_module(module_id):
  args = ['nix', 'build', '-L', '.#modules."%s"' % module_id, '--print-out-paths']
  print(" ".join(args))
  output = subprocess.check_output(args)
  return str(output, 'UTF-8').strip()

def get_upstream_modules(branch):
  args = ['git', 'show', '%s:modules.json' % branch]
  print(" ".join(args))
  output = subprocess.check_output(args)
  return json.loads(str(output, 'UTF-8'))

def nix_collect_garbage():
  args = ['nix-collect-garbage']
  print(" ".join(args))
  subprocess.run(args)

def main():
  parser = argparse.ArgumentParser(
    prog='build_changed_modules',
    description='builds the modules that were changed from an upstream branch',
  )

  parser.add_argument('upstream_branch')

  args = parser.parse_args()

  upstream_modules = get_upstream_modules(args.upstream_branch)
  upstream_ids = set(upstream_modules.keys())
  current_modules = get_modules()
  current_ids = set(current_modules.keys())
  new_modules = current_ids - upstream_ids
  for module_registry_id in new_modules:
    module_id, _ = module_registry_id.split(':')
    actual_path = build_module(module_id)
    # verify output is same as entry
    referenced_path = current_modules[module_registry_id]['path']
    assert actual_path == referenced_path, 'output path for %s does not match: %s vs %s' % (module_registry_id, actual_path, referenced_path)
    print('%s ok' % module_registry_id)
    nix_collect_garbage()

if __name__ == '__main__':
  main()
