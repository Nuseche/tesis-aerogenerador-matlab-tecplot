function hex=sha256(bytes)
%SHA256 SHA-256 of raw bytes; works with MATLAB sessions without Java.
if ischar(bytes)||isstring(bytes),bytes=unicode2native(char(bytes),'UTF-8');end
f=tempname;fid=fopen(f,'wb');
if fid<0,error('sensitivity:HashIO','Cannot create temporary hash input.');end
fwrite(fid,uint8(bytes),'uint8');fclose(fid);cleanup=onCleanup(@()delete(f));
quoted=[char(39) strrep(f,char(39),[char(39) char(34) char(39) char(34) char(39)]) char(39)];
[status,out]=system(['/usr/bin/shasum -a 256 ' quoted]);
if status~=0,error('sensitivity:HashFailure','SHA-256 command failed: %s',out);end
hex=string(out(1:64));
end
