import os,sys
import shlex,subprocess
from termcolor import colored

ARG = None
if len(sys.argv) == 2:
	ARG = sys.argv[1]
CONTRIB_ROOT="contrib"

def do_shell(COMMAND):
	print colored('* run command: ' + COMMAND, 'blue')
	lines = subprocess.check_output(shlex.split(COMMAND)).split('\n')
	if len(lines[-1]) == 0:
		del lines[-1]
	if len(lines) > 0:
		for line in lines:
			print line

def do_repo_sync_shell():
	print '<---------------'
	print colored('* update shell to lastest', 'green')
	try:
		do_shell('git pull')
	except subprocess.CalledProcessError:
		pass
	print '--------------->'

def do_repo_sync_commit(REPO_NAME, REPO_HASH):
	assert REPO_HASH
	print '<---------------'
	print colored('* update %s to commit %s' % (REPO_NAME, REPO_HASH), 'green')
	do_shell('git fetch origin')
	do_shell('git checkout %s -B sandbox' % (REPO_HASH))
	print '--------------->'

def do_repo_sync_branch(REPO_NAME, REPO_BRANCH):
	assert REPO_BRANCH
	print '<---------------'
	print colored('* update %s with branch %s' % (REPO_NAME, REPO_BRANCH), 'green')
	do_shell('git fetch origin')
	do_shell('git checkout %s' % (REPO_BRANCH))
	do_shell('git pull origin %s' % (REPO_BRANCH))
	print '--------------->'

def do_repo_sync_tag(REPO_NAME, REPO_TAG):
	assert REPO_TAG
	print '<---------------'
	print colored('* update %s with tag %s' % (REPO_NAME, REPO_TAG), 'green')
	do_shell('git fetch origin --tags')
	do_shell('git checkout %s' % (REPO_TAG))
	print '--------------->'

def do_check_sync(REPO_NAME, REPO_URL, REPO_EXPECT_TYPE, REPO_EXPECT_VALUE):
	assert REPO_NAME
	assert REPO_URL
	assert REPO_EXPECT_TYPE
	assert REPO_EXPECT_VALUE
	if not os.path.exists(REPO_NAME):
		do_shell('git clone %s %s' % (REPO_URL, REPO_NAME))
	currdir = os.getcwd()
	os.chdir(REPO_NAME)
	if REPO_EXPECT_TYPE == 'branch':
		do_repo_sync_branch(REPO_NAME, REPO_EXPECT_VALUE)
	elif REPO_EXPECT_TYPE == 'commit':
		do_repo_sync_commit(REPO_NAME, REPO_EXPECT_VALUE)
	elif REPO_EXPECT_TYPE == "tag":
		do_repo_sync_tag(REPO_NAME, REPO_EXPECT_VALUE)
	os.chdir(currdir)

def do_sync():
	do_repo_sync_shell()
	currdir = os.getcwd()
	if os.path.exists('dependencies'):
		fd = open('dependencies')
		raws = fd.readlines()
		fd.close()
		if not os.path.exists(CONTRIB_ROOT):
			os.mkdir(CONTRIB_ROOT)
		os.chdir(CONTRIB_ROOT)
		for i in xrange(len(raws)):
			raw = raws[i]
			items = raw.split()
			if len(items) != 4:
				if len(raw) <= 1:
					continue
				else:
					print colored('invalid dependencies, line %d:' % (i + 1), 'red')
					print colored(raw, 'red')
					break
			repo,url,eType,eValue = raw.split()
			do_check_sync(repo, url, eType, eValue)
	os.chdir(currdir)

if ARG and ARG.lower() == 'xcode':	
	pass
else:
	do_sync()
