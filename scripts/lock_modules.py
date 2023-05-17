import subprocess
import json
import os
import re
import argparse

module_id_regex = re.compile(r'^([a-zA-Z0-9.]+)-([a-zA-Z0-9.]+)-m([0-9]+)\.([0-9]+)$')
module_registry_file = 'modules.json'

def get_commit_info():
  output = subprocess.check_output(['git', 'show', '-s', '--format=format:%aI|%H|%s'])
  timestamp, commit, changelog = str(output, 'UTF-8').split('|')
  return {
    'sha': commit,
    'timestamp': timestamp,
    'changelog': changelog
  }

def is_working_directory_clean():
  output = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'])
  return len(output) == 0

def get_current_modules():
  output = subprocess.check_output(['nix', 'eval', '.#modules', '--json'])
  return json.loads(output)

def get_module_registry():
  if not os.path.isfile(module_registry_file):
    return {}
  f = open(module_registry_file, 'r')
  registry = json.load(f)
  f.close()
  return registry

def save_module_registry(registry):
  f = open(module_registry_file, 'w')
  json.dump(registry, f, indent = 2)
  f.close()
  print('Wrote %s' % module_registry_file)

def update_module_registry(module_registry):
  commit = get_commit_info()
  modules = get_current_modules()
  changed = False
  for module_id, modinfo in modules.items():
    module_path = modinfo["module"]
    if module_id in module_registry:
      # check for conflict
      prev_path = module_registry[module_id]['path']
      if module_path != prev_path:
        raise Exception('%s changed from %s to %s' % (module_id, prev_path, module_path))
      else:
        print('%s unchanged' % module_id)
        continue

    module_registry[module_id] = {
      'name': modinfo['name'],
      'description': modinfo['description'],
      'commit': commit['sha'],
      'created': commit['timestamp'],
      'changelog': commit['changelog'],
      'path': module_path,
    }
    print('%s added' % module_id)
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