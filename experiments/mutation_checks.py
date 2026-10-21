#!/usr/bin/env python3
"""Verify the tests fail when two important defenses are deliberately removed."""
from pathlib import Path
import json,os,shutil,subprocess,sys,tempfile
root=Path(__file__).resolve().parent
source=(root/'lab_model.py').read_text();results=[]
for name,before,after,required in [
 ('one-share-quorum','return len([s for s in "abc" if f"signer-{s}" in capabilities or f"share-{s}" in capabilities]) >= 2','return len([s for s in "abc" if f"signer-{s}" in capabilities or f"share-{s}" in capabilities]) >= 1','test_single_signer_cannot_control_quorum'),
 ('remove-trusted-latest-check','if checkpoint != trusted_latest:','if False:','test_old_matching_checkpoint_rejected_by_independent_latest_anchor'),
]:
 assert source.count(before)==1
 with tempfile.TemporaryDirectory(prefix='custody-lab-mutation-') as tmp:
  folder=Path(tmp);(folder/'lab_model.py').write_text(source.replace(before,after));shutil.copytree(root/'tests',folder/'tests')
  env=dict(os.environ,PYTHONPATH=str(folder));run=subprocess.run([sys.executable,'-m','unittest','discover','-s',str(folder/'tests'),'-v'],cwd=folder,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
  assert run.returncode!=0 and 'FAIL: '+required in run.stdout,(name,run.stdout)
  results.append({'mutation':name,'expected':'tests fail','actual':'tests failed as expected','return_code':run.returncode,'required_failure':required})
out=root.parent/'results/local/mutation-checks.json';out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(results,indent=2)+'\n')
print('Two deliberate defense mutations were detected by the test suite.')
