#!/usr/bin/env python3
from pathlib import Path
from xml.etree import ElementTree
import re,json,hashlib
R=Path(__file__).resolve().parents[1]
ignored={'.git','.terraform','__pycache__','node_modules'}
issues=[];count=0
for p in R.rglob('*'):
 if not p.is_file() or any(x in ignored for x in p.relative_to(R).parts) or 'results/local' in str(p):continue
 if p.suffix in {'.key','.pem','.p12','.pfx','.tfstate','.tfplan'} or p.name.startswith('.env'):issues.append('forbidden file: '+str(p.relative_to(R)))
 data=p.read_bytes()
 for pattern in [rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',rb'\bgh[pousr]_[A-Za-z0-9]{30,}\b',rb'\b(?:AKIA|ASIA)[A-Z0-9]{16}\b']:
  if re.search(pattern,data):issues.append('credential pattern: '+str(p.relative_to(R)))
 if p.suffix=='.svg':
  ElementTree.fromstring(data)
  if b'<script' in data or b'http' in data.replace(b'http://www.w3.org/2000/svg',b''):issues.append('active/remote SVG: '+p.name)
 if p.suffix=='.md':
  for target in re.findall(r'!?\[[^\]]*\]\(([^\s)]+)\)',data.decode()):
   if re.match(r'^(https?://|mailto:|#)',target):continue
   if not (p.parent/target.split('#')[0]).resolve().exists():issues.append(f'broken link {p.relative_to(R)}: {target}')
   count+=1
for p in (R/'terraform/environments').glob('*/tests/*.tftest.hcl'):
 text=p.read_text()
 if 'mock_provider "aws"' not in text or re.search(r'command\s*=\s*apply',text):issues.append('unsafe test provider/command: '+str(p))
# Broad public CIDRs, public addresses, SSH and runtime role escalation must not sneak in.
network=(R/'terraform/modules/network/main.tf').read_text()
if 'aws_internet_gateway' in network or 'aws_nat_gateway' in network:issues.append('unexpected Internet gateway')
workload=(R/'terraform/modules/workload/main.tf').read_text()
assert re.search(r'associate_public_ip_address\s*=\s*false',workload)
assert re.search(r'http_tokens\s*=\s*"required"',workload)
for name,expected in json.loads((R/'results/published/SHA256SUMS.json').read_text())['files'].items():
 if hashlib.sha256((R/name).read_bytes()).hexdigest()!=expected:issues.append('recorded evidence hash mismatch: '+name)
if issues:raise SystemExit('\n'.join(issues))
print(f'Publication, SVG, credential-pattern and safe-test checks passed; {count} local Markdown links verified.')
