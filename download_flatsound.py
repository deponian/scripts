#!/usr/bin/env python3

import os
from bs4 import BeautifulSoup
import requests as req

def download_album(album_name, album_link):
	os.mkdir(album_name)
	os.chdir(album_name)
	resp = req.get(album_link)
	soup = BeautifulSoup(resp.text, 'lxml')
	cover_link = soup.find_all("img")[0]['data-image']
	ext = cover_link.split('.')[-1]
	cover = req.get(cover_link)
	cover_name = "cover.{}".format(ext)
	with open(cover_name, 'wb') as cover_file:
		cover_file.write(cover.content)
	count = 1
	for track in soup.find_all("a", class_="link"):
		link = track['href']
		name = track.string.replace('/', '-')
		ext = link.split('.')[-1]
		filename = "{0:02d}. {1}.{2}".format(count, name, ext)
		print(filename)
		song = req.get(link)
		with open(filename, 'wb') as f:
			f.write(song.content)
		count += 1
	os.chdir("..")


def main():
	resp = req.get("https://www.flatsound.org/work")
	soup = BeautifulSoup(resp.text, 'lxml')

	bands = soup.find_all('p')[0:2] # get only flapsound and wishing
	for band in bands:
		band_name = band.contents[0].contents[0]
		os.mkdir(band_name)
		os.chdir(band_name)
		for album in band.find_all('a'):
			name = album.contents[0].split('(')[0][:-1].replace('/', 'and')
			year = album.contents[0].split('(')[1][:-1]
			link = "https://www.flatsound.org{}".format(album['href'])
			fullname = "{0} - {1}".format(year, name)
			print(fullname)
			download_album(fullname, link)
		os.chdir("..")

if __name__ == '__main__':
	main()
