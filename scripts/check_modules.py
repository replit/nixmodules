# This script checks module.json for:
#
# 1. all commits references exist in the linear history of the current branch
# 2. there are no duplicate numeric versions for the same module ID, say `go-1.19-v1-20230412-9uegy7e` 
#    and `go-1.19-v1-20230501-cceo023`

import subprocess
import os
import json

module_registry_file = 'modules.json'

def commit_exists(commit):
  try:
    output = subprocess.check_output(['git', 'show', '-s', '--format=format:%H', commit])
    return str(output, 'UTF-8') == commit
  except:
    return False

def get_commits(modules):
  commits = set()
  for entry in modules.values():
    commits.add(entry['commit'])
  return commits

def check_commits_exist(modules):
  for commit in get_commits(modules):
    assert commit_exists(commit), 'Commit %s does not exist!' % commit

def get_modules():
  if not os.path.isfile(module_registry_file):
    return {}
  f = open(module_registry_file, 'r')
  modules = json.load(f)
  f.close()
  return modules

def check_no_duplicate_numeric_versions(modules):
  uniques = {}
  for key in modules.keys():
    module_id, tag = key.split(':')
    version, _, _ = tag.split('-')
    short_key = "%s:%s" % (module_id, version)
    if short_key in uniques:
      raise Exception("%s has duplicate numeric versions: %s and %s" % (module_id, key, uniques[short_key]))
    uniques[short_key] = key

def main():
  modules = get_modules()
  check_commits_exist(modules)
  check_no_duplicate_numeric_versions(modules)

if __name__ == '__main__':
  main()
