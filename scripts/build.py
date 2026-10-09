#!/usr/bin/env python3
"""Reproducible universal app + ZIP + DMG, with optional Developer ID signing."""
import argparse, hashlib, os, plistlib, shutil, subprocess, tempfile
from pathlib import Path
parser=argparse.ArgumentParser(); parser.add_argument('--native',action='store_true'); args=parser.parse_args()
root=Path(__file__).resolve().parents[1]; version='0.3.0'; build='6'; dist=root/'dist'; dist.mkdir(exist_ok=True)
def run(*command, **kw): subprocess.run(command,check=True,**kw)
with tempfile.TemporaryDirectory(prefix='ScreenQR-package-') as temporary:
 stage=Path(temporary); app=stage/'QR Flick.app'; binary=app/'Contents/MacOS'; resources=app/'Contents/Resources'; binary.mkdir(parents=True);resources.mkdir()
 env=dict(os.environ,CLANG_MODULE_CACHE_PATH=str(stage/'clang'),SWIFTPM_MODULECACHE_OVERRIDE=str(stage/'modules'))
 arches=[os.uname().machine] if args.native else ['arm64','x86_64']; binaries=[]
 for arch in arches:
  scratch=Path(tempfile.gettempdir())/f'screenqr-release-{arch}'
  run('swift','build','--disable-sandbox','-c','release','--arch',arch,'--scratch-path',str(scratch),cwd=root,env=env)
  location=subprocess.check_output(['swift','build','--disable-sandbox','-c','release','--arch',arch,'--scratch-path',str(scratch),'--show-bin-path'],cwd=root,env=env,text=True).strip();binaries.append(str(Path(location)/'ScreenQR'))
 if len(binaries)>1: run('lipo','-create',*binaries,'-output',str(binary/'ScreenQR'))
 else: shutil.copy2(binaries[0],binary/'ScreenQR')
 run('swift',str(root/'scripts/make-app-icon.swift'),str(stage/'AppIcon.iconset'),env=env)
 run('iconutil','-c','icns',str(stage/'AppIcon.iconset'),'-o',str(resources/'AppIcon.icns'))
 metadata={'CFBundleExecutable':'ScreenQR','CFBundleIdentifier':'com.screenqr.app','CFBundleName':'QR Flick','CFBundleDisplayName':'QR Flick','CFBundlePackageType':'APPL','CFBundleShortVersionString':version,'CFBundleVersion':build,'CFBundleIconFile':'AppIcon','LSMinimumSystemVersion':'14.0','LSUIElement':True,'NSHighResolutionCapable':True,'CFBundleDevelopmentRegion':'en','CFBundleLocalizations':['en','ru']}
 (app/'Contents/Info.plist').write_bytes(plistlib.dumps(metadata))
 identity=os.environ.get('SCREENQR_SIGN_IDENTITY')
 run('xattr','-cr',str(app))
 if identity: run('codesign','--force','--options','runtime','--timestamp','--sign',identity,str(app))
 else: run('codesign','--force','--sign','-','--requirements','=designated => identifier "com.screenqr.app"',str(app))
 run('codesign','--verify','--deep','--strict',str(app));run('plutil','-lint',str(app/'Contents/Info.plist'))
 filename=f'QRFlick-{version}-macos';archive=dist/(filename+'.zip')
 run('ditto','--noextattr','--norsrc','-c','-k','--keepParent',str(app),str(archive));run('unzip','-tq',str(archive))
 dmgroot=stage/'dmg';dmgroot.mkdir();run('ditto','--noextattr',str(app),str(dmgroot/'QR Flick.app'));(dmgroot/'Applications').symlink_to('/Applications')
 dmg=dist/(filename+'.dmg');dmg.unlink(missing_ok=True)
 run('hdiutil','create','-volname','QR Flick','-srcfolder',str(dmgroot),'-format','UDZO',str(dmg))
 target=dist/'QR Flick.app'
 if target.exists(): shutil.rmtree(target)
 run('ditto','--noextattr',str(app),str(target));run('xattr','-cr',str(target))
 checks=dist/(filename+'.sha256');checks.write_text(''.join(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}\n' for path in [archive,dmg]))
 print(f'Built {version}: {", ".join(arches)}; '+('Developer ID signed' if identity else 'ad-hoc beta (not notarized)'))
 print(archive);print(dmg);print(checks)
