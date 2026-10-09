#!/usr/bin/env python3
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse, unquote
import json, xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]/'website/dist'
class Page(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.canonical=[];self.alternates={};self.headings=0;self.lang=None;self.description=None;self.schema=[];self.in_schema=False;self.schema_text='';self.title='';self.in_title=False
 def handle_starttag(self,tag,attrs):
  a=dict(attrs)
  if tag=='html':self.lang=a.get('lang')
  if tag=='h1':self.headings+=1
  if tag=='title':self.in_title=True
  if tag=='meta' and a.get('name')=='description':self.description=a.get('content')
  if tag=='link' and a.get('rel')=='canonical':self.canonical.append(a.get('href'))
  if tag=='link' and a.get('rel')=='alternate':self.alternates[a.get('hreflang')]=a.get('href')
  if tag in ['link','a']:self.links.append(a.get('href',''))
  if tag in ['img','script']:self.links.append(a.get('src',''))
  if tag=='script' and a.get('type')=='application/ld+json':self.in_schema=True;self.schema_text=''
 def handle_endtag(self,tag):
  if tag=='title':self.in_title=False
  if tag=='script' and self.in_schema:self.schema.append(json.loads(self.schema_text));self.in_schema=False
 def handle_data(self,data):
  if self.in_schema:self.schema_text+=data
  if self.in_title:self.title+=data
pages={};titles=set()
for path in root.rglob('index.html'):
 p=Page();p.feed(path.read_text());rel=path.relative_to(root).parent.as_posix();rel='' if rel=='.' else rel+'/'
 expected='https://kunilingvistador.github.io/QRFlick/'+rel
 assert p.canonical==[expected],(path,p.canonical)
 assert p.lang in ['ru','en'] and p.headings==1 and p.description and p.schema,path
 assert p.title not in titles,path;titles.add(p.title)
 assert set(p.alternates)=={'en','ru'} and p.alternates[p.lang]==expected,path
 assert p.schema[0]['url']==expected,path
 for link in p.links:
  if link.startswith('https://kunilingvistador.github.io/QRFlick/'):
   destination=unquote(urlparse(link).path[len('/QRFlick/'):]);target=root/destination
   if destination.endswith('/') or not destination:target=target/'index.html'
   assert target.is_file(),(path,link)
 pages[expected]=p
for url,p in pages.items():
 for lang,other in p.alternates.items():assert other in pages and pages[other].alternates[p.lang]==url,(url,other)
sitemap=ET.parse(root/'sitemap.xml');urls={element.text for element in sitemap.findall('.//{*}loc')};assert urls==set(pages)
assert (root/'404.html').is_file()
assert sum(p.stat().st_size for p in (root/'assets').glob('*'))<600000
print(f'PASS {len(pages)} pages: titles, canonicals, reciprocal languages, JSON-LD, links, sitemap and asset budget')
