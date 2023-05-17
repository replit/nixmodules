import os
import json
import subprocess
import argparse

module_registry_file = 'modules.json'

def get_upgrade_maps():
  output = subprocess.check_output(['nix', 'eval', '.#upgrade-maps', '--json'])
  return json.loads(output)

def get_module_registry():
  if not os.path.isfile(module_registry_file):
    return {}
  f = open(module_registry_file, 'r')
  registry = json.load(f)
  f.close()
  return registry

def resolve_module(module_id, upgrade_map):
  path = [module_id]
  while module_id in upgrade_map:
    module_id = upgrade_map[module_id]
    if module_id in path:
      raise Exception("Error: found cycle: %s -> %s" % (" -> ".join(path), module_id))
    path.append(module_id)
  return module_id

def check(module_id, upgrade_maps, reg):
  auto_result = resolve_module(module_id, upgrade_maps['auto'])
  if auto_result not in reg:
    raise Exception('Error: %s is not in the registry' % auto_result)
  if auto_result != module_id:
    print('Auto: %s -> %s' % (module_id, auto_result))
    print('  %s' % reg[auto_result]['changelog'])
  recommend_result = resolve_module(auto_result, upgrade_maps['recommend'])
  if recommend_result not in reg:
    raise Exception('Error: %s is not in the registry' % auto_result)
  if recommend_result != auto_result:
    print('Recommand: %s -> %s' % (auto_result, recommend_result))
    print('  %s' % reg[recommend_result]['changelog'])

def main():
  reg = get_module_registry()
  upgrade_maps = get_upgrade_maps()
  for module_id in reg.keys():
    check(module_id, upgrade_maps, reg)

if __name__ == '__main__':
    main()