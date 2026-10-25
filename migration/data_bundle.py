"""Pack or restore persisted runs/output with exact, portable SHA-256 checks."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, tarfile
ROOT=Path(__file__).resolve().parents[1]
MANIFEST=ROOT/'migration/data_manifest.json'

def sha(path):
    h=hashlib.sha256()
    with Path(path).open('rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()

def pack(folder):
    folder.mkdir(parents=True,exist_ok=True)
    paths=sorted(p for name in ['runs','output'] for p in (ROOT/name).rglob('*') if p.is_file() and p.name!='.DS_Store')
    files={};groups=[];group=[];size=0
    for p in paths:
        assert not p.is_symlink(),p
        n=p.stat().st_size
        if group and size+n>450*1024**2:groups.append(group);group=[];size=0
        group.append(p);size+=n
        files[p.relative_to(ROOT).as_posix()]={'bytes':n,'sha256':sha(p)}
    if group:groups.append(group)
    archives=[]
    for i,group in enumerate(groups,1):
        path=folder/f'persisted-data-{i:03d}.tar.gz'
        with tarfile.open(path,'w:gz',compresslevel=1) as tar:
            for p in group:tar.add(p,arcname=p.relative_to(ROOT).as_posix(),recursive=False)
        archives.append({'name':path.name,'bytes':path.stat().st_size,'sha256':sha(path),'files':len(group)})
        print(f'{i}/{len(groups)} {path.name}: {path.stat().st_size/1024**2:.1f} MiB',flush=True)
    result={'release_tag':'migration-data-20261025','repository':'Nuseche/tesis-aerogenerador-matlab-tecplot','archives':archives,'files':files}
    MANIFEST.write_text(json.dumps(result,indent=2)+'\n')
    print(f'{len(files)} files preserved; manifest saved.',flush=True)

def restore(folder):
    manifest=json.loads(MANIFEST.read_text())
    for a in manifest['archives']:
        p=folder/a['name']
        if not p.is_file() or sha(p)!=a['sha256']:raise ValueError('Missing/corrupt archive: '+str(p))
    for name,record in manifest['files'].items():
        dest=(ROOT/name).resolve()
        if not dest.is_relative_to(ROOT):raise ValueError(name)
        if dest.exists() and sha(dest)!=record['sha256']:raise ValueError('Existing different file; restore into a clean clone: '+name)
    seen=set()
    for a in manifest['archives']:
        with tarfile.open(folder/a['name'],'r:gz') as tar:
            for member in tar:
                if not member.isfile() or member.name not in manifest['files']:raise ValueError('Unexpected archive member: '+member.name)
                name=member.name;record=manifest['files'][name];dest=(ROOT/name).resolve()
                if name in seen or not dest.is_relative_to(ROOT) or member.size!=record['bytes']:raise ValueError(name)
                seen.add(name)
                if dest.exists():continue
                dest.parent.mkdir(parents=True,exist_ok=True);tmp=dest.with_name(dest.name+'.migration-tmp')
                try:
                    with tar.extractfile(member) as src,tmp.open('wb') as out:shutil.copyfileobj(src,out)
                    if sha(tmp)!=record['sha256']:raise ValueError('File digest mismatch: '+name)
                    os.replace(tmp,dest)
                finally:tmp.unlink(missing_ok=True)
        print('Verified/restored '+a['name'],flush=True)
    assert seen==set(manifest['files'])
    print(f'All {len(seen)} original files present and verified.')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['pack','restore']);parser.add_argument('--asset-dir',type=Path,default=ROOT/'.migration-cache')
    args=parser.parse_args()
    (pack if args.action=='pack' else restore)(args.asset_dir.resolve())
