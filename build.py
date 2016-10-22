import argparse
import io
import os
import json
import re
import subprocess


COMPILER_PATH = "../pawno/pawncc.exe"
CONSTANTS = []

try:
	with io.open("build-config.json") as f:
		config = json.load(f)

	COMPILER_PATH = config["compiler_path"]
	CONSTANTS = config['constants']

except IOError:
	print("Could not load build-config.json")


def build_project(increment=True):
	print("Building project...", flush=True)
	BUILD_NUMBER = 0

	with io.open("BUILD_NUMBER", 'r') as f:
		BUILD_NUMBER = int(f.read())

	if increment:
		BUILD_NUMBER = BUILD_NUMBER + 1

		with io.open("BUILD_NUMBER", 'w') as f:
			f.write(str(BUILD_NUMBER))

	print("BUILD", BUILD_NUMBER, flush=True)
	print("COMPILER", COMPILER_PATH, flush=True)
	print("CONSTANTS", CONSTANTS, flush=True)

	ret = subprocess.call([
		COMPILER_PATH,
		"-Dgamemodes/",
		"ScavengeSurvive.pwn",
		"-;+",
		"-(+",
		"-\\)+",
		"-d3",
		"-e../errors"
	] + [s + "=" for s in CONSTANTS])

	# fixes sublime text jump-to-error feature by adding `gamemodes/` directory
	# to errors and warnings.

	try:
		with io.open("errors", 'r') as f:
			print("Build result:", ret)
			for l in f:
				if re.match("[a-zA-Z]:\\.*", l):
					print(l, end='')

				else:
					print("gamemodes/" + l, end='')

		os.remove("errors")

	except:
		print("Build successful!")


def build_file(file):
	print("Building file", file, "...", flush=True)
	if not file:
		print("No file passed", flush=True)
		return

	output = "-o" + os.path.splitext(file)[0]

	ret = subprocess.call([
		COMPILER_PATH,
		file,
		output,
		"-;+",
		"-(+",
		"-\\)+",
		"-d3",
		"-e../errors"
	] + [s + "=" for s in CONSTANTS])

	try:
		with io.open("errors", 'r') as f:
			print("Build result:", ret)
			for l in f:
				if re.match("[a-zA-Z]:\\.*", l):
					print(l, end='')

				else:
					print("gamemodes/" + l, end='')

		os.remove("errors")

	except:
		print("Build successful!")


def main():

	parser = argparse.ArgumentParser()
	parser.add_argument('mode', help="mode: project|file")
	parser.add_argument('--increment', action="store_true")
	parser.add_argument('--input', type=str, default='')
	args = parser.parse_args()

	if args.mode == "project":
		build_project(args.increment)

	elif args.mode == "file":
		build_file(args.input)


if __name__ == '__main__':
	main()
