#!/usr/bin/env python3
"""Run local checks only. Never run a real AWS plan, apply or credential lookup."""
from pathlib import Path
from datetime import datetime, timezone
import json,os,subprocess,sys,platform
R=Path(__file__).resolve().parents[1];out=R/'results/local';out.mkdir(parents=True,exist_ok=True)
env={k:v for k,v in os.environ.items() if not k.startswith(('AWS_','TF_VAR_'))}
env.update({'AWS_EC2_METADATA_DISABLED':'true','AWS_SHARED_CREDENTIALS_FILE':'/dev/null','AWS_CONFIG_FILE':'/dev/null','PYTHONPATH':str(R/'experiments'),'TF_IN_AUTOMATION':'true'})
checks=[]
def run(name,command):
 result=subprocess.run(command,cwd=R,env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 (out/(name+'.log')).write_text(result.stdout)
 checks.append({'check':name,'command':command,'exit_code':result.returncode})
 print(f'{name}: {"PASS" if result.returncode==0 else "FAIL"}',flush=True)
 if result.returncode:
  print(result.stdout);raise RuntimeError(name)
try:
 run('publication',[sys.executable,'scripts/check-publication.py'])
 run('python-tests',[sys.executable,'-m','unittest','discover','-s','experiments/tests','-v'])
 run('model-scenarios',[sys.executable,'experiments/run.py'])
 run('mutation-checks',[sys.executable,'experiments/mutation_checks.py'])
 run('terraform-format',['terraform','fmt','-check','-recursive','terraform'])
 for domain in ['lab','security','recovery','organization']:
  prefix=['terraform',f'-chdir=terraform/environments/{domain}']
  run(domain+'-init',prefix+['init','-backend=false','-input=false','-lockfile=readonly','-no-color'])
  run(domain+'-validate',prefix+['validate','-no-color'])
  run(domain+'-tests',prefix+['test','-no-color'])
 run('diagram-rebuild',[sys.executable,'architecture/diagrams/render.py'])
 status='passed'
except (RuntimeError,FileNotFoundError) as error:
 status='failed';print(str(error),file=sys.stderr)
finally:
 (out/'validation.json').write_text(json.dumps({'executed_at':datetime.now(timezone.utc).isoformat(),'python':platform.python_version(),'status':status,'scope':'Local models, static configuration and mocked plan-only Terraform. No AWS resource operations.','checks':checks},indent=2)+'\n')
if status!='passed':sys.exit(1)
print('All local checks passed. No AWS authentication, real plan or apply was performed.')
