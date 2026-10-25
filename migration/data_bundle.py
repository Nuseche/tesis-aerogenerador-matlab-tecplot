"""Pack or restore persisted runs/output with exact, portable SHA-256 checks."""
from pathlib import Path
import argparse, hashlib, json, os, shutil, tarfile
from contextlib import contextmanager
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
    import zstandard
    files={p.relative_to(ROOT).as_posix():{'bytes':p.stat().st_size,'sha256':sha(p)} for p in paths}
    path=folder/'persisted-data.tar.zst'
    params=zstandard.ZstdCompressionParameters.from_level(10,window_log=30,threads=4)
    with path.open('wb') as raw,zstandard.ZstdCompressor(compression_params=params).stream_writer(raw) as writer:
        with tarfile.open(fileobj=writer,mode='w|') as tar:
            for p in paths:
                assert not p.is_symlink(),p
                tar.add(p,arcname=p.relative_to(ROOT).as_posix(),recursive=False)
    archives=[{'name':path.name,'bytes':path.stat().st_size,'sha256':sha(path),'files':len(files)}]
    result={'release_tag':'migration-data-20261025','repository':'Nuseche/tesis-aerogenerador-matlab-tecplot','archives':archives,'files':files}
    MANIFEST.write_text(json.dumps(result,indent=2)+'\n')
    print(f'{len(files)} files preserved; manifest saved.',flush=True)

@contextmanager
def open_archive(path):
    if path.name.endswith('.zst'):
        import zstandard
        with path.open('rb') as raw,zstandard.ZstdDecompressor(max_window_size=2**31).stream_reader(raw) as stream:
            with tarfile.open(fileobj=stream,mode='r|') as tar:yield tar
    else:
        with tarfile.open(path,'r:gz') as tar:yield tar

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
        with open_archive(folder/a['name']) as tar:
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
