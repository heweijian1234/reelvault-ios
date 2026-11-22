# -*- coding: utf-8 -*-
# RV 鱼实拍图抓取（Wikimedia Commons CC/PD——可商用）：
# 50种鱼学名→Commons搜索→取直链→下载→压缩到512×512 JPEG→Assets
# 无结果的种留空（图鉴回退FishArt剪影）
import urllib.request, urllib.parse, json, os, io, time

PROXY = 'socks5h://127.0.0.1:1080'
UA = 'Mozilla/5.0 (compatible; research)'
OUT = r'E:\AI-Projects\个人成长\10-项目\SaaS项目\reelvault-ios\fish_photos'
os.makedirs(OUT, exist_ok=True)

import subprocess
def api(url):
    r = subprocess.run(['curl', '-s', '--max-time', '25', '-x', PROXY, '-A', UA, url],
                       capture_output=True, text=True, timeout=30)
    return json.loads(r.stdout)

def search_best_image(sci):
    """Commons搜学名（File命名空间），取第一个许可宽松的"""
    q = urllib.parse.quote(sci)
    try:
        d = api(f'https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch={q}&gsrnamespace=6&gsrlimit=4&prop=imageinfo&iiprop=url%7Cextmetadata&format=json')
    except Exception as e:
        print(f'  搜索失败 {sci}: {e}')
        return None
    for p in d.get('query', {}).get('pages', {}).values():
        ii = p.get('imageinfo', [{}])[0]
        lic = ii.get('extmetadata', {}).get('LicenseShortName', {}).get('value', '')
        url = ii.get('url', '')
        if not url: continue
        # 宽松许可白名单（PD/CC0/CC-BY/CC-BY-SA均可商用）
        ok = any(k in lic for k in ['Public domain', 'CC0', 'CC BY', 'CC-BY'])
        if ok:
            return (url.split('?')[0], lic)
    return None

def download(url, path):
    # thumb.php 通道（commons 域缩略图——绕开 upload 域 429 限流；文件名从 url 尾段取）
    fname = url.rstrip('/').split('/')[-1]
    thumb = f'https://commons.wikimedia.org/w/thumb.php?f={fname}&width=480'
    for u in (thumb, url):
        r = subprocess.run(['curl', '-s', '-L', '--max-time', '60', '-x', PROXY, '-A', UA, u],
                           capture_output=True, timeout=70)
        data = r.stdout
        if data[:3] == bytes([0xFF, 0xD8, 0xFF]) or data[:4] == bytes([0x89]) + b'PNG' or data[:2] == b'BM':
            from PIL import Image
            img = Image.open(io.BytesIO(data)).convert('RGB')
            img.thumbnail((512, 512), Image.LANCZOS)
            img.save(path, 'JPEG', quality=82)
            return len(data)
    raise ValueError('not image: ' + repr(data[:20]))

# 50种（读SpeciesData.swift的学名）
import re
s = open(r'E:\AI-Projects\个人成长\10-项目\SaaS项目\reelvault-ios\Shared\SpeciesData.swift', encoding='utf-8').read()

species = re.findall('\.init\(name: "([^"]+)", nameSci: "([^"]+)", nameZh: "([^"]+)"', s)
print(f"共 {len(species)} 种")

manifest = []
for name, sci, zh in species:
    out_path = os.path.join(OUT, f'{name}.jpg')
    if os.path.exists(out_path):
        manifest.append((name, zh, sci, 'cached'))
        continue
    hit = search_best_image(sci)
    if not hit:
        print(f'✗ {zh} ({sci}): 无宽松许可图')
        manifest.append((name, zh, sci, 'MISS'))
        continue
    url, lic = hit
    try:
        size = download(url, out_path)
        print(f'✓ {zh}: {size//1024}KB [{lic}]')
        manifest.append((name, zh, sci, lic))
    except Exception as e:
        print(f'✗ {zh}: 下载失败 {str(e)[:50]}')
        manifest.append((name, zh, sci, 'DL_FAIL'))
    time.sleep(2.0)  # 礼貌限速

json.dump(manifest, open(os.path.join(OUT, '_manifest.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
hit_n = sum(1 for m in manifest if m[3] not in ('MISS', 'DL_FAIL'))
print(f'---完成: {hit_n}/{len(species)} 有图---')
