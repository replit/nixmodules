#!/usr/bin/python3
#
# scripts/nixmodules_oci.py
#
# This script:
# 1. for each historical version of each module from github:replit/nixmodules
#    a. if it doesn't already exist in the artifact registry
#    b. builds the phony OCI image
#    c. pushes it to Google Artifact Regsitry
#
# To run, make sure you are logged in via:
# gcloud auth login

import sys
import subprocess
import json
import tempfile
import atexit
import os

nix_flags = ['--extra-experimental-features', 'nix-command flakes discard-references']
docker_base_url = 'us-docker.pkg.dev/replit-user-deployments/gcr.io'

def main():
  rev = eval_rev()
  setup_docker_config()
  
  module_ids = get_all_module_ids()
  existing = get_module_ids_with_existing_oci(module_ids)
  for module_id in module_ids:
    if module_id not in existing:
      outpath = build_oci(module_id)
      publish_oci(module_id, outpath)

def build_oci(module_id):
  print('Building %s...' % module_id)
  output = exec([
    'nix', 'build', '.#all-phony-oci-bundles."%s"' % module_id,
    '--print-out-paths'
  ] + nix_flags)
  return str(output, 'UTF-8').strip()

def publish_oci(module_id, dirname):
  url = '%s/nixmodules-%s' % (docker_base_url, module_id)
  exec(['crane', 'push', dirname, url])

def get_all_module_ids():
  output = exec(['nix', 'eval', '.#all-modules', '--json'] + nix_flags)
  return list(json.loads(output).keys())

def get_module_ids_with_existing_oci(module_ids):
  print('Getting existing oci tags...')
  short_module_ids = get_short_module_ids(module_ids)
  module_ids = set()
  for short in short_module_ids:
    tags = get_existing_tags_for_short_module_id(short)
    for tag in tags:
      module_ids.add("%s:%s" % (short, tag))
  return module_ids

def get_existing_tags_for_short_module_id(module_id):
  url = '%s/nixmodules-%s' % (docker_base_url, module_id)
  output = exec(['crane', 'ls', url])
  return str(output, 'UTF-8').strip().split('\n')

# strips the tag from a module ID. ex: 'bun-0.5:v1-20230525-c48c43c' -> 'bun-0.5'
def get_short_module_id(module_id):
  short, _ = module_id.split(':')
  return short

def get_short_module_ids(module_ids):
  ids = set()
  for module_id in module_ids:
    ids.add(get_short_module_id(module_id))
  return ids

def eval_rev():
  output = exec([
    'sh', '-c', 
    'nix build --refresh .#rev --print-out-paths %s \'%s\' | xargs cat' % (
      nix_flags[0], nix_flags[1]
    )
  ])
  return str(output, 'UTF-8')

def setup_docker_config():
  tmpdir = tempfile.TemporaryDirectory()
  filepath = '%s/config.json' % tmpdir.name
  f = open(filepath, 'w')
  f.write('''
{
  "credHelpers": {
    "us-docker.pkg.dev": "gcloud"
  }
}
''')
  f.close()
  os.environ['DOCKER_CONFIG'] = tmpdir.name
  atexit.register(lambda: tmpdir.cleanup())

def exec(cmdargs):
  print(' '.join(cmdargs))
  output = subprocess.check_output(cmdargs)
  print('--> %s' % str(output, 'UTF-8'))
  return output

if __name__ == '__main__':
  main()