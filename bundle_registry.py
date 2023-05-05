import subprocess
import json
import os
import shutil

module_registry_file = 'modules.json'
output_dir = 'build/linkfarm'

def get_current_branch():
  args = ['git', 'branch', '--show-current']
  output = subprocess.check_output(args)
  return str(output, 'UTF-8').strip()

def get_module_registry():
  if not os.path.isfile(module_registry_file):
    return { 'modules': {}, 'aliases': {} }
  f = open(module_registry_file, 'r')
  registry = json.load(f)
  f.close()
  return registry

def group_by_commit(modules):
  by_commit = {}
  for module_id, module in modules.items():
    commit = module['commit']
    if commit not in by_commit:
      by_commit[commit] = []
    by_commit[commit].append(module_id)
  return by_commit

def checkout(commit):
  args = ['git', 'checkout', commit]
  print(" ".join(args))
  subprocess.run(args)

def build_module(module_id):
  args = ['nix', 'build', '.#modules."%s"' % module_id, '--out-link', "%s/%s" % (output_dir, module_id)]
  print(" ".join(args))
  subprocess.run(args)

def refresh_output_dir():
  if os.path.exists(output_dir):
    shutil.rmtree(output_dir)
  os.makedirs(output_dir)

def build_disk_image():
  args = ['bash', 'build_bundle_image.sh']
  print(" ".join(args))
  subprocess.run(args)

def main():
  original_branch = get_current_branch()
  refresh_output_dir()
  registry = get_module_registry()
  modules = registry['modules']
  modules_by_commit = group_by_commit(modules)
  for commit, modules in modules_by_commit.items():
    checkout(commit)
    for module_id in modules:
      build_module(module_id)
  checkout(original_branch)
  build_disk_image()

if __name__ == '__main__':
  main()