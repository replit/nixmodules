import json
import subprocess

def main():
  file = open('modules.json')
  modules = json.load(file)
  file.close()
  for module_id in modules.keys():
    cmd = [
      'scripts/cache_nix_build.sh', '.#all-historical-modules."%s"' % module_id
    ]
    print(" ".join(cmd))
    subprocess.check_output(cmd, stderr=subprocess.PIPE)
    print('%s done' % " ".join(cmd))

if __name__ == '__main__':
  main()