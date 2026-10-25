"""Upload this migration's data release and publish only after verification.

Runs independently of the chat. Authentication remains in GitHub CLI's keychain.
"""
from pathlib import Path
import argparse,hashlib,json,subprocess,time
ROOT=Path(__file__).resolve().parents[1]

def command(args):return subprocess.check_output(['gh',*args],text=True).strip()
def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()

def main(folder,release_id):
    manifest=json.loads((ROOT/'migration/data_manifest.json').read_text());repo=manifest['repository'];tag=manifest['release_tag']
    status=folder/'upload_status.json'
    def record(state,**extra):
        status.write_text(json.dumps({'state':state,'repository':repo,'tag':tag,'updated_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),**extra},indent=2)+'\n')
        print(state,flush=True)
    try:
        for a in manifest['archives']:
            path=folder/a['name'];assert path.stat().st_size==a['bytes'] and sha(path)==a['sha256']
            record('uploading',asset=a['name'],bytes=a['bytes'])
            for attempt in range(3):
                result=subprocess.run(['gh','release','upload',tag,str(path),'--repo',repo,'--clobber'])
                if result.returncode==0:break
                if attempt==2:raise RuntimeError('Upload failed after three attempts')
                time.sleep(15)
        release=json.loads(command(['api',f'repos/{repo}/releases/{release_id}']))
        assert release['tag_name']==tag
        for a in manifest['archives']:
            asset=next(x for x in release['assets'] if x['name']==a['name'])
            assert asset['state']=='uploaded' and asset['size']==a['bytes']
            if asset.get('digest'):
                assert asset['digest']=='sha256:'+a['sha256']
            else:
                record('verifying_download',asset=a['name'])
                proc=subprocess.Popen(['gh','api',f'repos/{repo}/releases/assets/{asset["id"]}','-H','Accept: application/octet-stream'],stdout=subprocess.PIPE)
                h=hashlib.sha256()
                for chunk in iter(lambda:proc.stdout.read(1048576),b''):h.update(chunk)
                assert proc.wait()==0 and h.hexdigest()==a['sha256']
        command(['release','edit',tag,'--repo',repo,'--draft=false'])
        release=json.loads(command(['api',f'repos/{repo}/releases/{release_id}']))
        assert release['draft'] is False
        record('published',url=release['html_url'],all_asset_sha256_verified=True)
    except Exception as exc:
        record('failed',error=str(exc));raise

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--asset-dir',type=Path,required=True);p.add_argument('--release-id',type=int,required=True)
    a=p.parse_args();main(a.asset_dir.resolve(),a.release_id)
