import json

formatters = {}
languageServers = {}
packagers = {}
with open('result', 'r') as f:
  data = json.load(f)
  for formatter in data['formatters']:
    if formatter['id'] not in formatters:
      formatters[formatter['id']] = []
    formatters[formatter['id']].append({
      'name': formatter['name'],
      'displayVersion': formatter['displayVersion'],
      'moduleId': formatter['moduleId']
    })
  for lsp in data['languageServers']:
    if lsp['id'] not in languageServers:
      languageServers[lsp['id']] = []
    languageServers[lsp['id']].append({
      'name': lsp['name'],
      'displayVersion': lsp['displayVersion'],
      'moduleId': lsp['moduleId']
    })
  for packager in data['packagers']:
    if packager['id'] not in packagers:
      packagers[packager['id']] = []
    packagers[packager['id']].append({
      'name': packager['name'],
      'displayVersion': packager['displayVersion'],
      'moduleId': packager['moduleId']
    })
print('Formatters:')
print(json.dumps(formatters, indent='  '))
print('Language Servers:')
print(json.dumps(languageServers, indent='  '))
print('Packagers:')
print(json.dumps(packagers, indent='  '))