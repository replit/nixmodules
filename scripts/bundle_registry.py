import subprocess
import json
import os
import shutil
import argparse

module_registry_file = 'modules.json'
output_dir = 'build/linkfarm'

def get_current_branch():
  args = ['git', 'branch', '--show-current']
  output = subprocess.check_output(args)
  return str(output, 'UTF-8').strip()

def get_module_registry():
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
  args = ['bash', 'scripts/build_bundle_image.sh']
  print(" ".join(args))
  subprocess.run(args)

def verify_links(modules):
  for module_id, module in modules.items():
    linkpath = "%s/%s" % (output_dir, module_id)
    outpath = os.readlink(linkpath)
    assert outpath == module['path'], "output path for %s does not match: %s vs %s" % (
      module_id, module['path'], outpath
    )
    print('verifed %s -> %s' % (module_id, outpath))

def main():
  parser = argparse.ArgumentParser(
    prog='bundle_registry',
    description='bundles the registry as defined by %s into a disk image' % module_registry_file,
  )

  parser.add_argument('-d', '--dryrun', action='store_true', help='dryrun: skips building the disk; creates only linkfarm')
  args = parser.parse_args()

  original_branch = get_current_branch()
  refresh_output_dir()
  registry = get_module_registry()
  modules_by_commit = group_by_commit(registry['modules'])
  for commit, modules in modules_by_commit.items():
    checkout(commit)
    for module_id in modules:
      build_module(module_id)
  checkout(original_branch)
  verify_links(registry['modules'])

  if not args.dryrun:
    build_disk_image()

if __name__ == '__main__':
  main()