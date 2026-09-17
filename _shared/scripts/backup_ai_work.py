"""Versioned local backup of E: workspaces. Never deletes source or backup versions."""
import argparse, hashlib, json, os, shutil, subprocess, time, uuid
from datetime import datetime, timezone
from pathlib import Path

DEST=Path(r'\\?\D:\AI_storage\backups\ai_work_versions')
ROOTS=[Path(r'\\?\E:\AI'),Path(r'\\?\E:\AI_worktrees')]
SKIP_DIRS={'node_modules','.venv','venv','__pycache__','.pytest_cache','.mypy_cache'}
SKIP_GIT={'objects','logs'}
def ordinary(p):return not p.is_symlink() and not os.path.isjunction(p)
def sha(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  for b in iter(lambda:f.read(4*1024*1024),b''):h.update(b)
 return h.hexdigest()
def write_json(p,value):
 p.parent.mkdir(parents=True,exist_ok=True)
 tmp=p.with_name(p.name+'.tmp')
 tmp.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 os.replace(tmp,p)
def backup():
 if shutil.disk_usage('D:\\').free<20*2**30:raise RuntimeError('D has less than 20 GiB free; no source changed')
 DEST.mkdir(parents=True,exist_ok=True)
 lock=DEST/'backup.lock'
 try:fd=os.open(lock,os.O_CREAT|os.O_EXCL|os.O_WRONLY)
 except FileExistsError:raise RuntimeError('Another backup or an interrupted backup owns backup.lock; inspect it before retrying')
 os.write(fd,str(os.getpid()).encode());os.close(fd)
 started=datetime.now(timezone.utc).isoformat()
 run=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+uuid.uuid4().hex[:6]
 snap=DEST/'snapshots'/run;snap.mkdir(parents=True)
 records=[];links=[];errors=[];bytes_read=0;new_objects=0;last=time.monotonic()
 try:
  prev={}
  latest=DEST/'latest.json'
  # A failed attempt can still contain individually verified files. Reuse those
  # records while retrying the missing files/bundles; never call it a success.
  attempts=sorted((DEST/'snapshots').glob('*/manifest.json'))
  if attempts:
   prior=json.loads(attempts[-1].read_text(encoding='utf-8'))
   prev={r['key']:r for r in prior['files']}
  for root in ROOTS:
   if not root.is_dir() or not ordinary(root):raise RuntimeError('Expected ordinary E source root '+str(root))
   for current,dirs,files in os.walk(root,followlinks=False,onerror=lambda e:errors.append({'path':e.filename,'error':str(e)})):
    base=Path(current)
    for d in dirs[:]:
     p=base/d;rel=p.relative_to(root)
     if not ordinary(p):
      links.append({'key':root.name+'/'+rel.as_posix(),'target':os.readlink(p)});dirs.remove(d);continue
     if d in SKIP_DIRS or (base.name=='.git' and d in SKIP_GIT):
      dirs.remove(d)
    for name in files:
     p=base/name;rel=p.relative_to(root);key=root.name+'/'+rel.as_posix()
     if not ordinary(p):
      links.append({'key':key,'target':os.readlink(p)});continue
     try:
      st=p.stat();sig=[st.st_size,st.st_mtime_ns]
      old=prev.get(key)
      if old and old['stat']==sig and (DEST/'objects'/old['sha256'][:2]/old['sha256']).is_file():
       records.append(old);continue
      tmp=snap/('copy-'+uuid.uuid4().hex+'.part');h=hashlib.sha256()
      with p.open('rb') as src,tmp.open('xb') as dst:
       for chunk in iter(lambda:src.read(4*1024*1024),b''):
        h.update(chunk);dst.write(chunk);bytes_read+=len(chunk)
      after=p.stat()
      if [after.st_size,after.st_mtime_ns]!=sig:
       tmp.unlink();errors.append({'path':key,'error':'changed during copy; retry backup'});continue
      digest=h.hexdigest();obj=DEST/'objects'/digest[:2]/digest
      obj.parent.mkdir(parents=True,exist_ok=True)
      if obj.exists():
       if obj.stat().st_size!=st.st_size or sha(obj)!=digest:raise RuntimeError('Existing object is corrupt: '+digest)
       tmp.unlink()
      else:
       if sha(tmp)!=digest:raise RuntimeError('Backup readback failed: '+key)
       os.replace(tmp,obj);new_objects+=1
      records.append({'key':key,'stat':sig,'sha256':digest})
      if time.monotonic()-last>45:
       print('BACKUP_PROGRESS files='+str(len(records))+' new_GiB='+str(round(bytes_read/2**30,2)),flush=True);last=time.monotonic()
      if shutil.disk_usage('D:\\').free<15*2**30:raise RuntimeError('D has less than 15 GiB free; source and prior versions preserved')
     except OSError as e:errors.append({'path':key,'error':str(e)})
  bundles=[]
  for label,repo in [('shared',r'E:\AI'),('fertility_model',r'E:\AI_worktrees\fertility_pivot_sprint_20260814')]:
   b=snap/(label+'.bundle')
   p=subprocess.run(['git','-C',repo,'bundle','create',str(b).removeprefix('\\\\?\\'),'--all'],capture_output=True)
   if p.returncode:errors.append({'path':repo,'error':'git bundle creation failed','detail':p.stderr.decode('utf-8',errors='replace')[:2000]});continue
   v=subprocess.run(['git','-C',repo,'bundle','verify',str(b).removeprefix('\\\\?\\')],capture_output=True)
   if v.returncode:errors.append({'path':repo,'error':'git bundle verification failed'})
   digest=sha(b);size=b.stat().st_size
   obj=DEST/'objects'/digest[:2]/digest;obj.parent.mkdir(parents=True,exist_ok=True)
   if obj.exists():
    if sha(obj)!=digest:raise RuntimeError('Stored bundle object is corrupt')
    b.unlink()
   else:os.replace(b,obj)
   os.link(obj,b)
   bundles.append({'file':b.name,'bytes':size,'sha256':digest,'verified':v.returncode==0})
  manifest={'snapshot':run,'started_utc':started,'completed_utc':datetime.now(timezone.utc).isoformat(),
   'roots':[str(p).removeprefix('\\\\?\\') for p in ROOTS],'files':records,'links':links,
   'bundles':bundles,'errors':errors,'passed':not errors,'new_objects':new_objects,'bytes_read':bytes_read,
   'scope':'Ordinary workspace files, including untracked/ignored work. Junction targets, dependency environments and Git objects/logs are omitted; committed objects are in verified Git bundles. External E data and spillover retain their D cutover copies and are not versioned by this job.'}
  write_json(snap/'manifest.json',manifest)
  if not errors:write_json(latest,{'snapshot':run,'completed_utc':manifest['completed_utc']})
  print(json.dumps({'snapshot':run,'passed':not errors,'files':len(records),'links':len(links),'errors':len(errors),'new_objects':new_objects,'GiB_read':round(bytes_read/2**30,2)}),flush=True)
  if errors:raise RuntimeError('Backup incomplete; manifest records failures')
  return manifest
 finally:
  lock.unlink(missing_ok=True)
def restore_sample(output):
 output=Path(output).resolve()
 if not str(output).lower().startswith('e:\\ai_storage\\spillover\\storage_cutover_restore_test'):
  raise RuntimeError('Restore test must use the dedicated E scratch directory')
 output=Path('\\\\?\\'+str(output));output.mkdir(parents=True,exist_ok=True)
 latest=json.loads((DEST/'latest.json').read_text(encoding='utf-8'))
 m=json.loads((DEST/'snapshots'/latest['snapshot']/'manifest.json').read_text(encoding='utf-8'))
 selected=[]
 for label,match in [('book',lambda s:s.startswith('AI/book/') and s.lower().endswith('.docx')),
  ('fertility_status',lambda s:'fertility_pivot_sprint_20260814/' in s and s.endswith('/STATUS.md')),
  ('governance',lambda s:s=='AI/AGENTS.md')]:
  rows=[r for r in m['files'] if match(r['key'])]
  if not rows:raise RuntimeError('Missing restore candidate '+label)
  row=sorted(rows,key=lambda r:r['key'])[0]
  target=output/(label+Path(row['key']).suffix)
  if target.exists():raise RuntimeError('Restore output already exists')
  shutil.copyfile(DEST/'objects'/row['sha256'][:2]/row['sha256'],target)
  passed=sha(target)==row['sha256']
  selected.append({'key':row['key'],'restored':str(target).removeprefix('\\\\?\\'),'sha256':row['sha256'],'passed':passed})
 assert all(r['passed'] for r in selected)
 result={'snapshot':latest['snapshot'],'passed':True,'files':selected}
 write_json(output/'restore_receipt.json',result);print(json.dumps(result))
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--restore-test');args=ap.parse_args()
 restore_sample(args.restore_test) if args.restore_test else backup()
