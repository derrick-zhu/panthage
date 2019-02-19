# -*- coding:utf-8 -*- 
import os,sys
import shlex,subprocess
from termcolor import colored

if len(sys.argv) < 2:
	print('please input a new tag name')
	print('release2develop.py tag_name')
	print('need to modify gits in script manually')
	exit(0)

def do_shell(COMMAND):
	print(colored('* run command: ' + COMMAND, 'blue'))
	lines = subprocess.check_output(shlex.split(COMMAND)).split('\n')
	if len(lines[-1]) == 0:
		del lines[-1]
	if len(lines) > 0:
		for line in lines:
			print(line)

def do_repo_new_tag(REPO_NAME, TAG_NAME):
	os.chdir('./contrib/' + REPO_NAME)
	print('<---------------')
	try:
		print(colored('new %s tag for %s' % (TAG_NAME, REPO_NAME), 'green'))
		do_shell('git tag ' + TAG_NAME)
		do_shell('git push origin tag ' + TAG_NAME)
	except:
		pass
	print('--------------->')
	os.chdir('../..')

def do_repo_to_develop(REPO_NAME, TAG_NAME):
	os.chdir('./contrib/' + REPO_NAME)
	print('<---------------')
	try:
		print(colored('merge %s tag to master' % (TAG_NAME), 'green'))
		do_shell('git checkout master')
		do_shell('git pull')
		do_shell('git merge ' + TAG_NAME)
		do_shell('git push')
		print(colored('merge master to develop', 'green'))
		do_shell('git checkout develop')
		do_shell('git pull')
		do_shell('git merge master')
		do_shell('git push')
	except:
		pass
	print('--------------->')
	os.chdir('../..')

mergeGits = [
	'BBPgcPad',
	'BBPgcPhone',
	'BBPad',
	'BBPadBase',
	'BBPhone',
	'BBPhoneBase',
	'BiliCore',
	'BiliUtils'
]
tagGits = [
	'BBPgcPad',
	'BBPgcPhone',
	'BBPad',
	'BBPadBase',
	'BBPhone',
	'BBPhoneBase',
	'BiliCore',
	'BiliUtils',
	'BFC',
	'BBAd',
	'BBUper',
	'BBLive',
	'BBLiveBC',
	'BBLivePad',
	'bililive-ios-base',
	'bililive-ios-videoclip',
	'bililive-ios-videoclipshow'
]
for git in tagGits:
	do_repo_new_tag(git, sys.argv[1])
for git in mergeGits:
	do_repo_to_develop(git, sys.argv[1])
