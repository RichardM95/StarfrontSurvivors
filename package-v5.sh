#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
export XDG_CONFIG_HOME=/tmp/godot-android-tools/config XDG_DATA_HOME=/tmp/godot-android-tools/data XDG_CACHE_HOME=/tmp/godot-android-tools/cache HOME=/tmp/godot-android-tools/home JAVA_HOME=/tmp/godot-android-tools/jdk
P=/tmp/starfront-v5-package
mkdir -p "$P" exports test-results/v5
T=/tmp/godot-android-tools/sdk/build-tools/35.0.1
name=StarfrontSurvivors-v0.5.0-Android-arm64.apk
python3 repack-v5-resources.py
"$T/zipalign" -P 16 -f 4 "$P/unsigned.apk" "exports/$name"
"$T/apksigner" sign --ks /tmp/godot-android-tools/data/godot/keystores/debug.keystore --ks-pass pass:android --key-pass pass:android --ks-key-alias androiddebugkey "exports/$name"
"$T/apksigner" verify --verbose --print-certs "exports/$name" >test-results/v5/android-signature.txt
"$T/zipalign" -c -P 16 -v 4 "exports/$name" >test-results/v5/android-alignment.txt
"$T/aapt" dump badging "exports/$name" >test-results/v5/android-manifest.txt
PYTHONPATH=/tmp/godot-android-tools/pydeps python3 - <<'PY'
import py7zr,hashlib,pathlib,json,zipfile
name='StarfrontSurvivors-v0.5.0-Android-arm64.apk'
a=pathlib.Path('exports')/name;z=pathlib.Path('exports/StarfrontSurvivors-v0.5.0-Android.7z')
with zipfile.ZipFile(a) as p:
 assert p.testzip() is None
 assert any(x.startswith('lib/arm64-v8a/') for x in p.namelist())
 assert not any(x.startswith(('lib/armeabi','lib/x86')) for x in p.namelist())
with py7zr.SevenZipFile(z,'w',filters=[{'id':py7zr.FILTER_LZMA2,'preset':9 | 0x80000000,'dict_size':33554432}]) as p:p.write(a,name)
with py7zr.SevenZipFile(z,'r') as p:p.extractall('/tmp/starfront-v5-package/verify')
h=lambda p:hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()
assert h(a)==h(pathlib.Path('/tmp/starfront-v5-package/verify')/name)
result={'apk_sha256':h(a),'archive_sha256':h(z),'apk_bytes':a.stat().st_size,'archive_bytes':z.stat().st_size,'within_16MiB':z.stat().st_size<16*1024*1024,'archive_roundtrip':True,'arm64_only':True}
pathlib.Path('test-results/v5/package.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
assert result['within_16MiB'],'Archive exceeds chat 16MiB cap'
PY
