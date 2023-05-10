import subprocess
import json
import os
import re
import argparse

module_id_regex = re.compile(r'^([a-zA-Z0-9.]+)-([a-zA-Z0-9.]+)-m([0-9]+)\.([0-9]+)$')
module_registry_file = 'modules.json'

def get_commit_info():
  output = subprocess.check_output(['git', 'show', '-s', '--format=format:%aI|%H'])
  timestamp, commit = str(output, 'UTF-8').split('|')
  return {
    'sha': commit,
    'timestamp': timestamp
  }

def is_working_directory_clean():
  output = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'])
  return len(output) == 0

def get_current_modules():
  output = subprocess.check_output(['nix', 'eval', '.#modules', '--json'])
  return json.loads(output)

def get_module_registry():
  if not os.path.isfile(module_registry_file):
    return { 'modules': {}, 'aliases': {} }
  f = open(module_registry_file, 'r')
  registry = json.load(f)
  f.close()
  return registry

def save_module_registry(registry):
  f = open(module_registry_file, 'w')
  json.dump(registry, f, indent = 2)
  f.close()
  print('Wrote %s' % module_registry_file)

def parse_module_id(module_id):
  match = module_id_regex.match(module_id)
  id, community_version, major, minor = match.groups()
  return {
    'id': id,
    'community_version': community_version,
    'major': major,
    'minor': minor,
  }

def is_version_greater(modinfo1, modinfo2):
  if modinfo1['community_version'] == modinfo2['community_version']:
    if modinfo1['major'] == modinfo2['major']:
      return modinfo1['minor'] > modinfo2['minor']
    return modinfo1['major'] > modinfo2['major']
  return is_semver_greater(modinfo1['community_version'], modinfo2['community_version'])

def is_semver_greater(semver1, semver2):
  parts1 = list(map(int, semver1.split('.')))
  parts2 = list(map(int, semver2.split('.')))
  assert len(parts1) == len(parts2), "comparing semvars that have different number of parts: %s vs %s" % (semver1, semver2)
  for i in range(len(parts1)):
    if parts1[i] > parts2[i]:
      return True
  return False

def generate_aliases(module_registry, upgrade_map):
  reverse_upgrade_map = {}
  for key, value in upgrade_map.items():
    reverse_upgrade_map[value] = key
  aliases = {}
  for module_id in module_registry.keys():
    modinfo = parse_module_id(module_id)
    short_alias = modinfo['id']
    medium_alias = "%s-%s" % (modinfo['id'], modinfo['community_version'])
    long_alias = "%s-%s-m%s" % (modinfo['id'], modinfo['community_version'], modinfo['major'])

    if short_alias not in aliases or is_version_greater(modinfo, parse_module_id(aliases[short_alias])):
      aliases[short_alias] = module_id
    if medium_alias not in aliases or is_version_greater(modinfo, parse_module_id(aliases[medium_alias])):
      aliases[medium_alias] = module_id
    if medium_alias in reverse_upgrade_map:
      second_medium_alias = reverse_upgrade_map[medium_alias]
      if second_medium_alias not in aliases or is_version_greater(modinfo, parse_module_id(aliases[second_medium_alias])):
        aliases[second_medium_alias] = module_id
    if long_alias not in aliases or is_version_greater(modinfo, parse_module_id(aliases[long_alias])):
      aliases[long_alias] = module_id
    if long_alias in reverse_upgrade_map:
      second_long_alias = reverse_upgrade_map[long_alias]
      if second_long_alias not in aliases or is_version_greater(modinfo, parse_module_id(aliases[second_long_alias])):
        aliases[second_long_alias] = module_id
  return aliases

def update_module_registry(module_registry):
  commit = get_commit_info()
  modules = get_current_modules()
  changed = False
  for module_id, module_path in modules.items():
    if module_id in module_registry:
      # check for conflict
      prev_path = module_registry[module_id]['path']
      if module_path != prev_path:
        raise Exception('%s changed from %s to %s' % (module_id, prev_path, module_path))
      else:
        print('%s unchanged' % module_id)
        continue

    module_registry[module_id] = {
      'commit': commit['sha'],
      'created': commit['timestamp'],
      'path': module_path
    }
    print('%s added' % module_id)
    changed = True
  return changed

def main():
  upgrade_map = {
    'nodejs-19': 'nodejs-20',
    'nodejs-19-m1': 'nodejs-20-m1',
  }
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

  module_registry_top_level = get_module_registry()
  module_registry = module_registry_top_level['modules']
  changed = update_module_registry(module_registry)

  if args.verify and changed:
    print('%s is not up to date!!' % module_registry_file)
    exit(1)

  if changed:
    aliases = generate_aliases(module_registry, upgrade_map)
    save_module_registry({
      'modules': module_registry,
      'aliases': aliases
    })

if __name__ == '__main__':
  main()