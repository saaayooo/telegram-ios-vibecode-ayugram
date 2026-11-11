"""Prepare temporary configuration/signing from Actions secrets; never log values."""
import base64
import json
import os
from pathlib import Path
import secrets
import subprocess

required = ['NVX_API_ID', 'NVX_API_HASH', 'NVX_TEAM_ID', 'NVX_CERTIFICATE_P12_BASE64', 'NVX_CERTIFICATE_PASSWORD', 'NVX_PROFILES_ZIP_BASE64']
missing = [name for name in required if not os.environ.get(name)]
if missing:
    raise SystemExit('Owner setup required. Missing Actions secrets: ' + ', '.join(missing))
root = Path(os.environ['RUNNER_TEMP']) / 'nvxgram-signing'
root.mkdir(mode=0o700, exist_ok=True)
configuration = json.loads(Path('build-system/template_minimal_development_configuration.json').read_text())
configuration.update(bundle_id='org.nvxgram.ios', api_id=int(os.environ['NVX_API_ID']), api_hash=os.environ['NVX_API_HASH'], team_id=os.environ['NVX_TEAM_ID'], app_specific_url_scheme='nvxgram', is_internal_build='false')
(root / 'configuration.json').write_text(json.dumps(configuration))
os.chmod(root / 'configuration.json', 0o600)
(root / 'certs').mkdir(exist_ok=True)
(root / 'profiles').mkdir(exist_ok=True)
certificate = root / 'certs' / 'signing.p12'
certificate.write_bytes(base64.b64decode(os.environ['NVX_CERTIFICATE_P12_BASE64'], validate=True))
os.chmod(certificate, 0o600)
import io
import zipfile
with zipfile.ZipFile(io.BytesIO(base64.b64decode(os.environ['NVX_PROFILES_ZIP_BASE64'], validate=True))) as archive:
    for member in archive.infolist():
        if member.is_dir():
            continue
        if not member.filename.endswith('.mobileprovision'):
            raise SystemExit('Profiles archive must contain only mobileprovision files')
        target = root / 'profiles' / Path(member.filename).name
        if target.exists():
            raise SystemExit('Duplicate profile filename')
        target.write_bytes(archive.read(member))
        os.chmod(target, 0o600)
keychain = str(root / 'build.keychain-db')
password = secrets.token_hex(32)
def security(*args):
    # security output can include private metadata. Fail without echoing it or argv.
    result = subprocess.run(['security', *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        raise SystemExit('Keychain setup failed; check certificate/password and runner permissions')
security('create-keychain', '-p', password, keychain)
security('set-keychain-settings', '-lut', '21600', keychain)
security('unlock-keychain', '-p', password, keychain)
security('list-keychains', '-d', 'user', '-s', keychain, str(Path.home() / 'Library/Keychains/login.keychain-db'))
security('import', str(certificate), '-k', keychain, '-P', os.environ['NVX_CERTIFICATE_PASSWORD'], '-T', '/usr/bin/codesign', '-T', '/usr/bin/security')
security('set-key-partition-list', '-S', 'apple-tool:,apple:,codesign:', '-s', '-k', password, keychain)
print('Temporary signing configuration prepared; values omitted.')
