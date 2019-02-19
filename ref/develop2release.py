# -*- coding:utf-8 -*- 
import os,sys
import shlex,subprocess
from termcolor import colored

if len(sys.argv) < 2:
	print('please input a new relase branch name')
	print('develop2release.py branch_name [-hd|-blue|-other]')
	exit(0)

def do_shell(COMMAND):
	print(colored('* run command: ' + COMMAND, 'blue'))
	lines = subprocess.check_output(shlex.split(COMMAND)).split('\n')
	if len(lines[-1]) == 0:
		del lines[-1]
	if len(lines) > 0:
		for line in lines:
			print(line)

def do_repo_new_branch(REPO_NAME, BRANCH_NAME):
	os.chdir('./contrib/' + REPO_NAME)
	print('<---------------')
	print(colored('new %s branch for %s' % (BRANCH_NAME, REPO_NAME), 'green'))
	try:
		do_shell('git checkout -b ' + BRANCH_NAME)
		do_shell('git push -u origin ' + BRANCH_NAME)
	except:
		pass
	print('--------------->')
	os.chdir('../..')

ourGits = ['BBPgcPad', 'BBPad', 'BBPadBase', 'BBPgcPhone', 'BBPhone', 'BBPhoneBase', 'BiliCore', 'BiliUtils']
hdGits = ['BBPgcPad', 'BBPad', 'BBPadBase', 'BiliCore', 'BiliUtils']
blueGits = ['BBPgcPhone', 'BBPhone', 'BBPhoneBase', 'BiliCore', 'BiliUtils']
otherGits = ['BBAd', 'BBUper', 'BBLive', 'BBLiveBC', 'BBLivePad', 'bililive-ios-base', 'bililive-ios-videoclip', 'bililive-ios-videoclipshow']
if len(sys.argv) == 3 and (sys.argv[2] == '-o' or sys.argv[2] == '-other'):
	# 带 -o 参数，把其它的库都切出release分支
	for git in otherGits:
		do_repo_new_branch(git, sys.argv[1])
elif len(sys.argv) == 3 and (sys.argv[2] == '-h' or sys.argv[2] == '-hd'):
	# 带 -h 参数，把HD的库都切出release分支
	for git in hdGits:
		do_repo_new_branch(git, sys.argv[1])
elif len(sys.argv) == 3 and (sys.argv[2] == '-b' or sys.argv[2] == '-blue'):
	# 带 -b 参数，把纯蓝（phone）的库都切出release分支
	for git in blueGits:
		do_repo_new_branch(git, sys.argv[1])
else:
	# 不带参数，把我们自己的库切出release分支，注意BFC是三不管分支
	for git in ourGits:
		do_repo_new_branch(git, sys.argv[1])
