#!/usr/bin/env python3
"""Deterministic vector diagrams from declarative nodes/edges; no external packages."""
from pathlib import Path
from html import escape
R=Path(__file__).resolve().parent

def diagram(name,title,subtitle,rows,edges,height=790):
    nodes={k:(x,y,w,h,text,kind) for k,x,y,w,h,text,kind in rows}
    s=f'<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="{height}" viewBox="0 0 1200 {height}" role="img" aria-label="{escape(title)}"><defs><marker id="a" markerWidth="8" markerHeight="8" refX="7" refY="4" orient="auto"><path d="M0 0L8 4L0 8" fill="none" stroke="#244d68"/></marker></defs><rect width="1200" height="{height}" fill="white"/><g font-family="Arial,sans-serif" fill="#182c3c"><text x="35" y="40" font-size="27" font-weight="bold">{escape(title)}</text><text x="35" y="72" font-size="16">{escape(subtitle)}</text>'
    for a,b,style in edges:
        x,y,w,h,_,_=nodes[a];xx,yy,ww,hh,_,_=nodes[b]
        if yy>y:x1,y1,x2,y2=x+w/2,y+h,xx+ww/2,yy
        elif xx>x:x1,y1,x2,y2=x+w,y+h/2,xx,yy+hh/2
        else:x1,y1,x2,y2=x,y+h/2,xx+ww,yy+hh/2
        s+=f'<path d="M{x1} {y1}L{x2} {y2}" stroke="{("#9a3d36" if style else "#244d68")}" stroke-width="2" fill="none" marker-end="url(#a)"'+(' stroke-dasharray="7 5"' if style else '')+'/>'
    for k,(x,y,w,h,lines,kind) in nodes.items():
        border,fill={'normal':('#244d68','#f1f5f8'),'control':('#2b6a54','#eef6f1'),'risk':('#9a3d36','#fcf1ef')}[kind]
        s+=f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="7" stroke="{border}" fill="{fill}" stroke-width="1.5"/>'
        for i,line in enumerate(lines):s+=f'<text x="{x+w/2}" y="{y+29+25*i}" text-anchor="middle" font-size="{18 if i==0 else 15}"'+(' font-weight="bold"' if i==0 else '')+f'>{escape(line)}</text>'
    s+=f'<text x="35" y="{height-22}" font-size="15">Solid: intended control/data path. Dashed red: explicit unsafe capability or lost trust assumption.</text></g></svg>'
    (R/(name+'.svg')).write_text(s)

rows=[]
for key,x,lines,kind in [('rpc',35,['Ethereum / private RPC proxy','Coordinator HTTPS path','Proxy not implemented'],'normal'),('coord',435,['Coordinator | account D','Private VPC / lifecycle host','No signer backup authority'],'normal'),('auth',835,['Authorization | account E','Independent approval authority','Application integration deferred'],'control')]:rows.append((key,x,120,330,120,lines,kind))
for key,x in [('a',35),('b',435),('c',835)]:rows.append((key,x,335,330,120,[f'Signer {key.upper()} | account {key.upper()}','Private VPC / mTLS peer 8443','One share + KMS envelope'],'normal'))
for key,x,lines,kind in [('audit',35,['Security | account F','CloudTrail / retained audit store','Independent checkpoint authority'],'control'),('recovery',435,['Recovery | account G','Versioned / locked evidence store','Separate backup/checkpoint writers'],'control'),('common',835,['Common authority risks','Organization / CI / CA / recovery','Account labels are not a proof'],'risk')]:rows.append((key,x,600,330,120,lines,kind))
diagram('aws-custody','AWS Institutional Custody Architecture','Reference domains. Terraform provisions infrastructure shells; no AWS or custody application deployment was executed.',rows,[('coord','rpc',False),('coord','auth',False),('coord','a',False),('coord','b',False),('coord','c',False),('a','audit',False),('b','recovery',False),('c','common',True)])
rows=[('shared',425,110,350,80,['Shared deployment authority','Unsafe counterexample'],'risk')]
for key,x in [('a',35),('b',435),('c',835)]:
 rows.extend([(f'admin-{key}',x,290,330,95,[f'Domain {key.upper()} administrator','Exact local bootstrap roles'],'normal'),(f'deploy-{key}',x,465,330,95,[f'Deploy {key.upper()} / key admin {key.upper()}',f'Runtime {key.upper()} + envelope context {key.upper()}'],'control'),(key,x,640,330,80,[f'Signer {key.upper()}','One domain does not control quorum'],'normal')])
edges=[]
for key in 'abc':edges.extend([('shared',f'admin-{key}',True),(f'admin-{key}',f'deploy-{key}',False),(f'deploy-{key}',key,False)])
diagram('iam-trust','IAM Trust and Deployment Boundaries','Separate domain administration is an assumption to verify. No shared AWS deployment role is created.',rows,edges)
rows=[];edges=[]
pairs=[(['One signer / one domain admin','One share or execution boundary'],['No quorum control','One share and availability still exposed'],'normal','control'),(['Two signers / shared deployer','Two or more signing domains controlled'],['Direct signing authority','Application approvals can be bypassed'],'risk','risk'),(['Coordinator only','Orchestration + retained signed bytes'],['No new approval authority','Issued bytes remain portable'],'normal','control'),(['Both approval keys','Human intent can be misrepresented'],['Policy-permitted business fraud','Standing signer limits still apply'],'risk','risk')]
for i,(a,b,sa,sb) in enumerate(pairs):
 y=125+i*140;rows.extend([(f'a{i}',35,y,430,90,a,sa),(f'b{i}',735,y,430,90,b,sb)]);edges.append((f'a{i}',f'b{i}',sa=='risk'))
diagram('compromise','Compromise Scenarios and Consequences','Executed capability models, not AWS escalation tests, MPC integration or a production vulnerability.',rows,edges,height=740)
rows=[('snapshot',35,130,330,115,['Signer snapshot','Epoch / nonce / consumed IDs','Application envelope before upload'],'normal'),('store',435,130,330,115,['Retained S3 versions','Backup-prefix writer only','COMPLIANCE + versioning'],'normal'),('anchor',835,130,330,115,['Independent current anchor','Digest / generation / policy epoch','Different publisher and admin'],'control'),('gate',435,385,330,115,['Reviewed restore gate','Two declared recovery approvals','Match snapshot + trusted latest'],'control'),('reject',35,620,330,95,['Reject stale / missing evidence','Fail closed; preserve history'],'control'),('restore',435,620,330,95,['Restore current state','Reconcile sessions and signed bytes'],'normal'),('rollback',835,620,330,95,['Joint state + anchor rollback','Counterexample: replay is possible'],'risk')]
diagram('disaster-recovery','Disaster Recovery and Trusted Recency','Retention preserves versions; independently governed current evidence determines which version is safe.',rows,[('snapshot','store',False),('store','gate',False),('anchor','gate',False),('gate','reject',False),('gate','restore',False),('gate','rollback',True)])
print('Four deterministic SVG diagrams rendered.')
