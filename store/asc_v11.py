"""Blacklist 1.1 on App Store Connect: rename the rejected 1.0 version to 1.1,
upload 16-locale texts and screenshots, attach the newest build, set review notes.
Never submits. Usage: python asc_v11.py [version] [texts] [shots] [build] [notes]"""
import hashlib
import io
import json
import os
import sys

import requests
from PIL import Image

import asc_client as asc

APP = '6816247755'
ROOT = os.path.dirname(os.path.abspath(__file__))
META = json.load(open(os.path.join(ROOT, 'metadata.json'), encoding='utf-8'))
DIRS = {'it': 'it', 'en-US': 'en', 'fr-FR': 'fr', 'de-DE': 'de', 'es-ES': 'es', 'pt-PT': 'pt', 'nl-NL': 'nl',
        'pl': 'pl', 'ro': 'ro', 'sv': 'sv', 'ru': 'ru', 'uk': 'uk', 'tr': 'tr', 'ar-SA': 'ar', 'zh-Hans': 'zh', 'ja': 'ja'}
SETS = {'iphone': 'APP_IPHONE_67', 'ipad': 'APP_IPAD_PRO_3GEN_129'}
NOTES = (
    "Version 1.1 adds substantial new functionality in a new Messages tab:\n"
    "1) SMS scam filter (IdentityLookup Message Filter extension): scam texts from unknown senders are moved to Junk, "
    "fully offline, using a multilingual rule set (fake courier, bank, requests for codes, shortened/odd links, prize, "
    "'hi mum' and crypto scams), the community spam numbers and the user's own blocked words. "
    "Enable it in Settings > Apps > Messages > Unknown & Spam > SMS Filtering > Blacklist.\n"
    "2) Check a message: paste any suspicious SMS/chat/email text and see the verdict and the warning signs found.\n"
    "No message ever leaves the device. The call blocking uses a CallKit Call Directory extension "
    "(Settings > Apps > Phone > Call Blocking & Identification). No login is required.\n"
    "The 'Remove Ads' purchase is in Settings > Ads, with Restore purchases below it."
)

args = sys.argv[1:]


def call(method, path, payload=None, params=None):
    url = path if path.startswith('http') else asc.BASE_URL + path
    r = requests.request(method, url, headers=asc._headers(), json=payload, params=params, timeout=120)
    if r.status_code >= 400:
        raise RuntimeError(f'{method} {path} {r.status_code}: {r.text[:500]}')
    return r.json() if r.text else {}


version = call('GET', f'/apps/{APP}/appStoreVersions', params={'limit': 1})['data'][0]
vid = version['id']
print('version', version['attributes']['versionString'], version['attributes']['appStoreState'])

if 'version' in args and version['attributes']['versionString'] != '1.1':
    call('PATCH', f'/appStoreVersions/{vid}', {'data': {'type': 'appStoreVersions', 'id': vid, 'attributes': {'versionString': '1.1'}}})
    print('renamed to 1.1')

if 'texts' in args:
    info = [i for i in call('GET', f'/apps/{APP}/appInfos')['data'] if i['attributes'].get('state') != 'READY_FOR_DISTRIBUTION'][0]
    info_locs = {l['attributes']['locale']: l for l in call('GET', f"/appInfos/{info['id']}/appInfoLocalizations", params={'limit': 50})['data']}
    ver_locs = {l['attributes']['locale']: l for l in call('GET', f'/appStoreVersions/{vid}/appStoreVersionLocalizations', params={'limit': 50})['data']}
    for loc, m in META.items():
        try:
            if loc in info_locs:
                call('PATCH', f"/appInfoLocalizations/{info_locs[loc]['id']}", {'data': {'type': 'appInfoLocalizations', 'id': info_locs[loc]['id'],
                     'attributes': {'subtitle': m['subtitle']}}})
            if loc in ver_locs:
                call('PATCH', f"/appStoreVersionLocalizations/{ver_locs[loc]['id']}", {'data': {'type': 'appStoreVersionLocalizations',
                     'id': ver_locs[loc]['id'], 'attributes': {'description': m['description'], 'promotionalText': m['promo'], 'keywords': m['keywords']}}})
            print('texts', loc)
        except RuntimeError as e:
            print('texts ERROR', loc, str(e)[:300])

if 'shots' in args:
    ver_locs = {l['attributes']['locale']: l for l in call('GET', f'/appStoreVersions/{vid}/appStoreVersionLocalizations', params={'limit': 50})['data']}
    for loc, folder in DIRS.items():
        vl = ver_locs[loc]['id']
        sets = {s['attributes']['screenshotDisplayType']: s for s in call('GET', f'/appStoreVersionLocalizations/{vl}/appScreenshotSets')['data']}
        for device, dtype in SETS.items():
            path = os.path.join(ROOT, 'screenshots', device, folder)
            files = sorted(f for f in os.listdir(path) if f.endswith('.png'))
            if dtype in sets:
                for shot in call('GET', f"/appScreenshotSets/{sets[dtype]['id']}/appScreenshots")['data']:
                    call('DELETE', f"/appScreenshots/{shot['id']}")
                set_id = sets[dtype]['id']
            else:
                set_id = call('POST', '/appScreenshotSets', {'data': {'type': 'appScreenshotSets', 'attributes': {'screenshotDisplayType': dtype},
                              'relationships': {'appStoreVersionLocalization': {'data': {'type': 'appStoreVersionLocalizations', 'id': vl}}}}})['data']['id']
            for name in files:
                buf = io.BytesIO()
                Image.open(os.path.join(path, name)).convert('RGB').save(buf, 'PNG')
                data = buf.getvalue()
                shot = call('POST', '/appScreenshots', {'data': {'type': 'appScreenshots', 'attributes': {'fileName': f'{folder}-{device}-{name}', 'fileSize': len(data)},
                            'relationships': {'appScreenshotSet': {'data': {'type': 'appScreenshotSets', 'id': set_id}}}}})['data']
                for op in shot['attributes']['uploadOperations']:
                    requests.request(op['method'], op['url'], data=data[op['offset']:op['offset'] + op['length']],
                                     headers={h['name']: h['value'] for h in op['requestHeaders']}, timeout=120).raise_for_status()
                call('PATCH', f"/appScreenshots/{shot['id']}", {'data': {'type': 'appScreenshots', 'id': shot['id'],
                     'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(data).hexdigest()}}})
            print('shots', loc, device, len(files))

if 'build' in args:
    builds = call('GET', '/builds', params={'filter[app]': APP, 'sort': '-uploadedDate', 'limit': 5, 'include': 'preReleaseVersion'})
    pre = {p['id']: p['attributes']['version'] for p in builds.get('included', [])}
    cand = [b for b in builds['data'] if b['attributes']['processingState'] == 'VALID'
            and pre.get(b['relationships']['preReleaseVersion']['data']['id']) == '1.1.0']
    if not cand:
        raise SystemExit('no VALID 1.1.0 build yet: ' + str([(b['attributes']['version'], b['attributes']['processingState']) for b in builds['data']]))
    b = cand[0]
    if b['attributes'].get('usesNonExemptEncryption') is None:
        call('PATCH', f"/builds/{b['id']}", {'data': {'type': 'builds', 'id': b['id'], 'attributes': {'usesNonExemptEncryption': False}}})
    call('PATCH', f'/appStoreVersions/{vid}/relationships/build', {'data': {'type': 'builds', 'id': b['id']}})
    print('attached build', b['attributes']['version'])

if 'notes' in args:
    detail = call('GET', f'/appStoreVersions/{vid}/appStoreReviewDetail').get('data')
    call('PATCH', f"/appStoreReviewDetails/{detail['id']}", {'data': {'type': 'appStoreReviewDetails', 'id': detail['id'], 'attributes': {'notes': NOTES}}})
    print('review notes set')
