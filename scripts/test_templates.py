#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python311Packages.requests

import requests
from time import sleep
import sys
import argparse

jitter_wait = 5 * 60
TEMPLATE_TESTER_URL = "https://templatetester.tobyho.repl.co"
HEADERS = {
  "Authorization": "BLARGH",
}
TEMPLATES_TO_TEST = [
  "@replit/Blank-Repl",
  "@replit/Python",
  "@replit/Nodejs",
  "@replit/Nodejs-Beta",
  # "@replit/Java",
#   "@replit/CSharp",
#   "@replit/HTML-CSS-JS",
#   "@replit/Go",
#   "@replit/C",
#   "@replit/Python-with-Turtle",
#   "@replit/Pygame-Beta",
#   "@replit/TypeScript",
#   "@replit/React-Javascript",
#   "@replit/PHP-Web-Server",
#   "@replit/Kaboom",
#   "@replit/Rust",
#   "@replit/Bun",
]

def main():
  parser = argparse.ArgumentParser(
    prog='test_templates',
    description='Run template tests')
  parser.add_argument('-m', '--nix-modules-version')
  parser.add_argument('-p', '--pid1-version')
  args = parser.parse_args()

  if args.nix_modules_version is not None and args.pid1_version is not None:
    raise Exception("Please only provide one of -m and -p")

  if args.nix_modules_version:
    wait_till_nix_modules_matches(args.nix_modules_version)
  elif args.pid1_version:
    wait_till_pid1_matches(args.pid1_version)

  job_id = create_test_job()
  print("Started job %d" % job_id)
  test_poll_wait = 10
  while True:
    sleep(test_poll_wait)
    reply = get_test_job_status(job_id)
    if reply["complete"]:
      passed = print_test_results(reply["TestRuns"])
      if passed:
        print("Pass")
      else:
        print("Fail")
        exit(1)
      break
    else:
      print(".", end="")
      sys.stdout.flush()

def wait_till_nix_modules_matches(expected_version):
  while True:
    print("checking Nix modules version...")
    version = get_nix_modules_version()
    if version != expected_version:
      print("Nix modules version %s does not match expected: %s" % (version, expected_version))
      sleep(jitter_wait)
    else:
      print("Nix modules version matches!")
      break

def wait_till_pid1_matches(expected_version):
  while True:
    print("checking Pid1 modules version...")
    version = get_pid1_version()
    if version != expected_version:
      print("Pid1 version %s does not match expected: %s" % (version, expected_version))
      sleep(jitter_wait)
    else:
      print("Pid1 version matches!")
      break

def get_nix_modules_version():
  resp = requests.get(
    "%s/nix-modules-version" % TEMPLATE_TESTER_URL,
    headers = HEADERS
  )
  return resp.json()["version"]

def get_pid1_version():
  resp = requests.get(
    "%s/pid1-version" % TEMPLATE_TESTER_URL,
    headers = HEADERS
  )
  return resp.json()["version"]

def create_test_job():
  resp = requests.post(
    "%s/jobs" % TEMPLATE_TESTER_URL,
    json = {
      "templates": TEMPLATES_TO_TEST
    },
    headers = HEADERS
  )
  reply = resp.json()
  return reply["jobId"]

def get_test_job_status(job_id):
  resp = requests.get(
    "%s/jobs/%d" % (TEMPLATE_TESTER_URL, job_id),
    headers = HEADERS
  )
  return resp.json()

def print_test_results(test_runs):
  print()
  print("Results:")
  passed = True
  for run in test_runs:
    result = run["result"]
    print("%s %s: %s" % (run["templateUri"], run["testCase"], result))
    if result != "P" and result != "S":
      passed = False
  return passed

if __name__ == "__main__":
  main()