#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python311Packages.requests

import requests
import time
from time import sleep
import sys
import argparse
import subprocess
import base64

global_timeout = 3600
version_mismatch_wait = 15 * 60
test_poll_wait = 10

TEMPLATE_TESTER_URL = "https://template-tester.replit.app"
TEMPLATES_TO_TEST = [
  "@replit/Blank-Repl",
  "@replit/Python",
  "@replit/Nodejs",
  "@replit/Nodejs-Beta",
  # "@replit/Java", skip for now due to flaky lsp tests
  "@replit/CSharp",
  "@replit/HTML-CSS-JS",
  "@replit/Go",
  "@replit/C",
  "@replit/Python-with-Turtle",
  "@replit/Pygame-Beta",
  "@replit/TypeScript",
  "@replit/React-Javascript",
  "@replit/PHP-Web-Server",
  "@replit/Kaboom",
  "@replit/Rust",
  "@replit/Bun",
]

def main():
  parser = argparse.ArgumentParser(
    prog='test_templates',
    description='Run template tests')
  parser.add_argument('-m', '--nix-modules-version')
  parser.add_argument('-p', '--pid1-version')
  args = parser.parse_args()

  auth = get_jobs_auth()

  start = time.time()
  done = False
  while not done:
    job_id = create_test_job(args, auth)
    print("Started job %d" % job_id)
    while True:
      reply = get_test_job_status(job_id, auth)

      if not reply["complete"]:
        print(".", end="")
        sys.stdout.flush()
        sleep(test_poll_wait)
        continue
      
      test_runs = reply["TestRuns"]
      if version_mismatch(test_runs):
        duration = time.time() - start
        if duration > global_timeout:
          print("Giving up after %ds" % duration)
          exit(1)
        else:
          sleep(version_mismatch_wait)
          break
      
      done = True
      print_test_results(test_runs)
      if passed(test_runs):
        print("Pass")
      else:
        print("Fail")
        exit(1)
      break  

def create_test_job(args, auth):
  resp = requests.post(
    "%s/jobs" % TEMPLATE_TESTER_URL,
    json = {
      "templates": TEMPLATES_TO_TEST,
      "nixModulesVersion": args.nix_modules_version,
      "pid1Version": args.pid1_version,
    },
    headers = { 'Authorization': auth }
  )
  reply = resp.json()
  return reply["jobId"]

def get_test_job_status(job_id, auth):
  resp = requests.get(
    "%s/jobs/%d" % (TEMPLATE_TESTER_URL, job_id),
    headers = { 'Authorization': auth }
  )
  return resp.json()

def version_mismatch(test_runs):
  for run in test_runs:
    result = run["result"]
    # Nix modules version mismatch or Pid1 version mismatch
    if result == "MV" or result == "PV":
      return True
  return False

def passed(test_runs):
  for run in test_runs:
    result = run["result"]
    # Not pass and not skip
    if result != "P" and result != "S":
      return False
  return True

def print_test_results(test_runs):
  print()
  print("Results:")
  for run in test_runs:
    result = run["result"]
    print("%s %s: %s" % (run["templateUri"], run["testCase"], result))

def get_jobs_auth():
  output = subprocess.check_output([
    'kubectl', 'get',
    'secret', 'jobs-auth', 
    '-n', 'nixmodules', '-o',
    'jsonpath={.data.jobs-auth}'
  ])
  return str(base64.b64decode(output), 'UTF-8').strip()

if __name__ == "__main__":
  main()