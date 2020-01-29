from lxml import html
import requests
import os
import subprocess

base = 'http://k7records.bandcamp.com'
page = requests.get(base)
tree = html.fromstring(page.content)
albums = [e for e in tree.xpath('//a') if e.get('href','').startswith('/album')]
tracks = [e for e in tree.xpath('//a') if e.get('href','').startswith('/track')]

def get_albums():
    for a in albums:
        artist = a.find_class('artist-override')
        if len(artist) > 0:
            artist = artist[0].text.strip()
        else:
            artist = None
        title = a.find_class('title')[0].text.strip()
        if artist is not None:
            title = artist + ' - ' + title
        title = title.replace('/', '_')
        url = base + a.get('href')
        if not os.path.isdir(title):
            os.mkdir(title)
            subprocess.check_call(["youtube-dl", "--ignore-errors", url], cwd=title)

def get_tracks():
    for t in tracks:
        url = base + t.get('href')
        subprocess.check_call(["youtube-dl", url])

get_albums()
get_tracks()

