# -*- coding: utf-8 -*-
import os,sys
import shlex,subprocess
import re

versionPattern = re.compile(r'(<key>CFBundleShortVersionString</key>\s+<string>)[\S]+(</string>)')
buildPattern = re.compile(r'(<key>CFBundleVersion</key>\s+<string>)(\d+)(</string>)')

if len(sys.argv) < 4:
	print 'python version.py branch_name universal|ipad version=5.6 build=5550'
	exit(0)

currentBranch = sys.argv[1]
target = sys.argv[2]
newVersion = None
newBuild = None

def do_shell(COMMAND):
	print '* run command: ' + COMMAND
	lines = subprocess.check_output(shlex.split(COMMAND)).split('\n')
	if len(lines[-1]) == 0:
		del lines[-1]
	if len(lines) > 0:
		for line in lines:
			print line

def do_repo_sync():
	assert currentBranch
	assert target
	print '<---------------'
	do_shell('git checkout ' + currentBranch)
	do_shell('git pull origin ' + currentBranch)
	do_version_update('bili-%s/bili-%s/Info.plist' % (target, target))
	if target == 'universal':
		do_version_update('bili-universal/BiliIMessageExtension/Info.plist')
		do_version_update('bili-universal/BiliWidgetExtension/Info.plist')
		do_version_update('bili-universal/BiliNotificationServiceExtension/Info.plist')
	do_shell('git add .')
	do_shell('git commit --allow-empty -m "auto version"')
	do_shell('git push origin ' + currentBranch)
	print '--------------->'

def do_version_update(infoFile):
	global newBuild
	fd = open(infoFile, 'r')
	raws = fd.read()
	fd.close()
	if newVersion:
		match = versionPattern.search(raws)
		if match:
			raws = raws.replace(match.group(0), match.group(1) + newVersion + match.group(2))
	if newBuild:
		match = buildPattern.search(raws)
		if match:
			if newBuild == '+10':
				newBuild = int(match.group(2)) + 10
				newBuild = newBuild - newBuild % 10
				newBuild = str(newBuild)
			elif newBuild == '+1':
				newBuild = int(match.group(2)) + 1
				newBuild = str(newBuild)
			raws = raws.replace(match.group(0), match.group(1) + newBuild + match.group(3))
	fd = open(infoFile, 'w')
	raws = fd.write(raws)
	fd.close()

def read_argv(ARGV):
	assert ARGV
	global newVersion
	global newBuild
	if ARGV[0:8] == 'version=' and newVersion == None:
		newVersion = ARGV[8:]
	elif ARGV[0:6] == 'build=' and newBuild == None:
		newBuild = ARGV[6:]
	elif ARGV == 'build+1' and newBuild == None:
		newBuild = '+1'
	elif ARGV == 'build+10' and newBuild == None:
		newBuild = '+10'

do_shell('git reset --hard')
do_shell('git clean -fd')
if len(sys.argv) >= 4:
	read_argv(sys.argv[3])
if len(sys.argv) >= 5:
	read_argv(sys.argv[4])
if newVersion:
	print 'version=' + newVersion
print 'build=' + newBuild
do_repo_sync()
print 'version.py done'
