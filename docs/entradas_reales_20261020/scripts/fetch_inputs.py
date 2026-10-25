"""Download primary-source inputs; retain originals, HTTP ranges and hashes.

No wind-to-force conversion or rescaling of earthquake amplitude is performed.
The DTU archive is 7.19 GB: retrieve its directory and selected members only.
"""
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import urllib.error
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'sources'
SOURCES.mkdir(exist_ok=True)


def request(url, headers=None):
    for attempt in range(3):
        effective_url = url
        # Refresh the public redirector's expiring signed download link.
        if attempt and 'ndownloader.figshare.com' in url:
            effective_url += f'?refresh={time.time_ns()}'
        try:
            with urllib.request.urlopen(urllib.request.Request(effective_url, headers=headers or {}), timeout=45) as response:
                return response.read(), dict(response.headers), response.status
        except (urllib.error.URLError, TimeoutError):
            if attempt == 2: raise


class RemoteZip(io.RawIOBase):
    def __init__(self, url, size):
        self.url, self.size, self.position = url, size, 0
        self.requests = []

    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.size) + offset
        if not 0 <= self.position <= self.size: raise ValueError('Invalid archive offset')
        return self.position

    def read(self, size=-1):
        if size < 0: size = self.size - self.position
        size = min(size, self.size - self.position)
        if size == 0: return b''
        start, end = self.position, self.position + size - 1
        data, headers, status = request(self.url, {'Range': f'bytes={start}-{end}'})
        assert status == 206 and len(data) == size, (status, len(data), size)
        assert headers['Content-Range'].startswith(f'bytes {start}-{end}/')
        self.requests.append({'start': start, 'end': end, 'bytes': len(data)})
        self.position += size
        return data


def main():
    raw, _, _ = request('https://api.figshare.com/v2/articles/16743739')
    (SOURCES / 'dtu_16743739_metadata.json').write_bytes(raw)
    metadata = json.loads(raw)
    entry = next(f for f in metadata['files'] if f['name'] == 'NM92.zip')
    remote = RemoteZip(entry['download_url'], entry['size'])
    with zipfile.ZipFile(remote) as archive:
        files = [f for f in archive.infolist() if not f.is_dir()]
        (SOURCES / 'nm92_archive_members.json').write_text(json.dumps([
            {'name': f.filename, 'size': f.file_size, 'compressed_size': f.compress_size,
             'crc32': f'{f.CRC:08x}'} for f in files], indent=2))
        print('Archive members:', len(files), flush=True)
        print('\n'.join(f.filename for f in files[:16]), flush=True)
        # Start with first lexicographic file for inspection; do not silently
        # choose favorable wind conditions or discard invalid samples.
        chosen = sorted(files, key=lambda f: f.filename)[0]
        destination = SOURCES / 'nm92_first_member'
        data = archive.read(chosen)  # zipfile verifies the member CRC32.
        destination.write_bytes(data)
        (SOURCES / 'nm92_selection.json').write_text(json.dumps({
            'doi': '10.11583/DTU.16743739', 'member': chosen.filename,
            'selection_rule': 'first lexicographic non-directory member; preliminary inspection',
            'sha256': hashlib.sha256(data).hexdigest(), 'crc32': f'{chosen.CRC:08x}',
            'archive_size': entry['size'], 'range_requests': remote.requests,
            'licence': metadata['license'], 'note': 'Wind and seismic sources are independent.'
        }, indent=2))
        print('Selected', chosen.filename, len(data), data[:120], flush=True)

    if (SOURCES / 'earthquake_provenance.json').exists(): return
    repository = json.loads(request('https://api.github.com/repos/OpenSees/OpenSees/commits/master')[0])
    commit = repository['sha']
    gm = [
        'EXAMPLES/ExampleScripts/ARL360.at2',
        'EXAMPLES/ExampleScripts/elCentro.AT2',
        'Workshops/SimWorkshop/SmallMP/GM/CHY023-W.AT2',
        'Workshops/SimWorkshop/SmallMP/GM/TCU052-N.AT2',
    ]
    provenance = []
    for path in gm:
        url = f'https://raw.githubusercontent.com/OpenSees/OpenSees/{commit}/{path}'
        data, _, _ = request(url)
        filename = SOURCES / Path(path).name
        filename.write_bytes(data)
        provenance.append({'url': url, 'commit': commit, 'file': filename.name,
                           'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)})
        print(filename.name, data[:280].decode(errors='replace'), flush=True)
    (SOURCES / 'earthquake_provenance.json').write_text(json.dumps(provenance, indent=2))


if __name__ == '__main__': main()
