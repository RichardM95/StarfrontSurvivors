import zipfile,struct,hashlib,pathlib,json
base=pathlib.Path('exports/StarfrontSurvivors-v0.5.0-Android-arm64.apk')
p=zipfile.ZipFile('/tmp/starfront-v5-package/current-resources.zip')
z=zipfile.ZipFile(base)
files={n:p.read(n) for n in p.namelist() if not n.endswith('/')}
header=z.read('assets/assets.sparsepck')[:104]
sparse=bytearray(header+struct.pack('<I',len(files)))
for n,b in files.items():
 name=n.encode();name+=b'\0'*((-len(name))%4)
 sparse+=struct.pack('<I',len(name))+name+struct.pack('<QQ',0,len(b))+hashlib.md5(b).digest()+struct.pack('<I',0)
changes=[n for n,b in files.items() if 'assets/'+n not in z.namelist() or z.read('assets/'+n)!=b]
with zipfile.ZipFile('/tmp/starfront-v5-package/unsigned.apk','w',compression=zipfile.ZIP_STORED) as out:
 for n in z.namelist():
  if n.startswith('META-INF/'):continue
  if n.startswith('assets/') and not(n.startswith('assets/dexopt/') or n=='assets/_cl_'):continue
  out.writestr(n,z.read(n))
 for n,b in files.items():out.writestr('assets/'+n,b)
 out.writestr('assets/assets.sparsepck',sparse)
pathlib.Path('test-results/v5/resource-repack.json').write_text(json.dumps({'resource_count':len(files),'changed':changes,'resource_zip_sha256':hashlib.sha256(pathlib.Path(p.filename).read_bytes()).hexdigest(),'sparse_index_regenerated':True},indent=2))
print('Repacked',len(files),'resources; sparse index regenerated;',changes)
