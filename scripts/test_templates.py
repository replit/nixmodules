#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python311Packages.requests

import requests
from time import sleep
import sys

TEMPLATE_TESTER_URL = "https://templatetester.tobyho.repl.co"
HEADERS = {
  "Authorization": "BLARGH",
}
TEMPLATES_TO_TEST = [
  "@replit/Blank-Repl",
  "@replit/Python",
  "@replit/Nodejs",
  "@replit/Nodejs-Beta",
  "@replit/Java",
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
  job_id = create_test_job()
  print("Started job %d" % job_id)

  while True:
    sleep(5)
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
    print("%s %s: %s" % (run["templateUri"], run["testCase"], run["result"]))
    if run["result"] != "P":
      passed = False
  return passed

if __name__ == "__main__":
  main()