#!/usr/bin/env python3
from glob import glob
from os.path import split
from pathlib import Path
from shutil import copy2
from subprocess import Popen
from time import sleep

INPUT_DIR = '/mnt/deponia/storage/Конвертеры/FLAC в Opus/FLAC'
OUTPUT_DIR = '/mnt/deponia/storage/Конвертеры/FLAC в Opus/Opus'
COMPLETED = '/mnt/deponia/storage/Конвертеры/FLAC в Opus/Конвертирование завершено'
PROCESSING = '/mnt/deponia/storage/Конвертеры/FLAC в Opus/Выполняется конвертирование'
PARALLELIZATION = 16 # number of parallel conversions

def setup_output_dirs():
	# create output directories
	flac_paths = set(glob(INPUT_DIR + "/**/*.flac", recursive=True))
	for path in flac_paths:
		dir = split(path[len(INPUT_DIR):])[0]
		Path(OUTPUT_DIR + dir).mkdir(parents=True, exist_ok=True)

	# copy all non-flac files to output dirs (like cover.jpg and etc)
	all_paths = set(glob(INPUT_DIR + "/**/*", recursive=True))
	all_paths = [path for path in all_paths if Path(path).is_file()] # remove dirs
	downloaded_paths = set(get_downloaded(all_paths))
	for input_path in downloaded_paths - flac_paths:
		output_path = OUTPUT_DIR + input_path[len(INPUT_DIR):]
		if not Path(output_path).is_file():
			print("Copying {}".format(input_path), flush=True)
			copy2(input_path, output_path)

# return list of paths of files which were already downloaded
# which means they aren't in the middle of copying process and
# we can safely convert them
def get_downloaded(paths):
	# get size for every file, wait 1 second, check if size has changed
	paths_size = {}
	for path in paths:
		try:
			paths_size[path] = Path(path).stat().st_size
		except FileNotFoundError:
			pass

	sleep(1)

	downloaded_paths = []
	for path, size in paths_size.items():
		try:
			current_size = Path(path).stat().st_size
		except FileNotFoundError:
			continue

		if current_size == size:
			downloaded_paths.append(path)

	return downloaded_paths

# return relative paths without extension
def get_not_converted():
	all_full_paths = glob(INPUT_DIR + "/**/*.flac", recursive=True)
	downloaded_full_paths = get_downloaded(all_full_paths)
	downloaded_short_paths = set()
	for path in downloaded_full_paths:
		downloaded_short_paths.add(path[len(INPUT_DIR):-len(".flac")])

	completed_full_paths = glob(OUTPUT_DIR + "/**/*.opus", recursive=True)
	completed_short_paths = set()
	for path in completed_full_paths:
		completed_short_paths.add(path[len(OUTPUT_DIR):-len(".opus")])

	return list(downloaded_short_paths - completed_short_paths)

def main():
	processes = []
	while True:
		setup_output_dirs()
		unfinished = get_not_converted()
		if len(unfinished) == 0:
			# print('Nothing to do...')
			if Path(PROCESSING).is_file():
				Path(PROCESSING).unlink()
			Path(COMPLETED).touch(exist_ok=True)
			sleep(1)
			continue
		else:
			for song in unfinished[0:PARALLELIZATION - len(processes)]:
				input = INPUT_DIR + song + ".flac"
				output = OUTPUT_DIR + song + ".opus"
				process = Popen(["ffmpeg", "-n", "-v", "0", "-i", input, "-b:a", "128000", output])
				print("Converting {}".format(input), flush=True)
				processes.append(process)
			if Path(COMPLETED).is_file():
				Path(COMPLETED).unlink()
			Path(PROCESSING).touch(exist_ok=True)
			sleep(1)

		still_running = []

		for process in processes:
			if process.poll() is None:
				still_running.append(process)

		processes = still_running

if __name__ == '__main__':
	main()
