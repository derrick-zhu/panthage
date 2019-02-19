# -*- coding: utf-8 -*-
import os,sys
import shlex,subprocess
import re

projectPattern = re.compile(r'#(\d{4,6})')

currentBranch = None
if len(sys.argv) == 2:
	currentBranch = sys.argv[1].replace('/', '$')
CONTRIB_ROOT = 'contrib'
changeLogs = ''
currentHash = ''
lastHash = {}

def do_shell(COMMAND):
	lines = subprocess.check_output(shlex.split(COMMAND)).split('\n')
	if len(lines[-1]) == 0:
		del lines[-1]
	if len(lines) > 0:
		return lines
	return False

def get_current_branch():
	lines = do_shell('git status')
	if lines:
		line = lines[0]
		if len(line) > 10 and line[0:10] == 'On branch ':
			return line[10:].replace('/', '$')
	return None

def get_current_hash():
	lines = do_shell('git log -1 --pretty=format:%h')
	if lines:
		return lines[0]
	raise Exception('Cannot get current hash.')

def make_change_logs(REPO_LINK, REPO_SINCE):
	assert REPO_LINK
	assert REPO_SINCE
	global changeLogs
	lines = do_shell('git log ' + REPO_SINCE + '..HEAD --pretty=format:"<a href=%x22' + REPO_LINK +'%H%x22>%h</a> by <a href=%x22mailto:%ae%x22>%an</a>%n%s%n" --no-merges')
	if lines:
		for line in lines:
			match = projectPattern.search(line)
			while match:
				line = line.replace(match.group(0), '#<a href="http://project.bilibili.co/issues/%s">%s</a>' % (match.group(1), match.group(1)))
				match = projectPattern.search(line, match.end() + 1)
			changeLogs += line + '<br>'
	else:
		changeLogs = changeLogs + 'Unknown error.'

def make_sub_log(REPO_NAME, REPO_URL, REPO_EXPECT_TYPE, REPO_EXPECT_VALUE):
	assert REPO_NAME
	assert REPO_URL
	assert REPO_EXPECT_TYPE
	assert REPO_EXPECT_VALUE
	global currentHash
	global changeLogs
	if not os.path.exists(REPO_NAME):
		raise Exception('Cannot find repo folder.')
	currdir = os.getcwd()
	os.chdir(REPO_NAME)
	current = get_current_hash()
	currentHash = currentHash + '%s %s\n' % (REPO_NAME, current)
	if lastHash.has_key(REPO_NAME):
		changeLogs = changeLogs + '<h1>==== %s ====</h1>' % (REPO_NAME)
		if lastHash[REPO_NAME] == current:
			changeLogs = changeLogs + '<h3>Current hash: %s<br><br>No changes.' % (current)
		else:
			changeLogs = changeLogs + '<h3>Hash: %s...%s<br><br>' % (lastHash[REPO_NAME], current)
			if REPO_NAME == 'ijkplayer':
				link = 'http://syncsvn.bilibili.co/app/ijkplayer/commit/'
			else:
				link = 'http://syncsvn.bilibili.co/ios/%s/commit/' % (REPO_NAME)
			make_change_logs(link, lastHash[REPO_NAME])
		changeLogs = changeLogs + '</h3>'
	os.chdir(currdir)

def make_all_logs():
	global currentBranch
	# 记录原目录位置
	currdir = os.getcwd()
	# 获得当前分支名，并尝试获得上一次拉取到的 hash 位置
	if not currentBranch:
		currentBranch = get_current_branch()
	if currentBranch and os.path.exists('%s/%s' % (CONTRIB_ROOT, currentBranch)):
		fd = open('%s/%s' % (CONTRIB_ROOT, currentBranch), 'r')
		raws = fd.readlines()
		fd.close()
		for i in xrange(len(raws)):
			raw = raws[i]
			rawl = raw.split()
			assert len(rawl) == 2
			repo,commit = raw.split()
			assert repo
			assert commit
			lastHash[repo] = commit
#	# 逐个生成各个子分支的修改日志
#	if os.path.exists('dependencies'):
#		fd = open('dependencies', 'r')
#		raws = fd.readlines()
#		fd.close()
#		if not os.path.exists(CONTRIB_ROOT):
#			raise Exception('Cannot find contrib root.')
#		os.chdir(CONTRIB_ROOT)
#		for i in xrange(len(raws)):
#			raw = raws[i]
#			rawl = raw.split()
#			assert len(rawl) == 4
#			repo,url,eType,eValue = raw.split()
#			assert repo
#			assert url
#			assert eType
#			assert eValue
#			make_sub_log(repo, url, eType, eValue)
	# 写入这一次拉取到的 hash 位置
	fd = open('lastHash.txt', 'w')
	fd.writelines(currentHash)
	fd.close()
	fd = open(currentBranch, 'w')
	fd.writelines(currentHash)
	fd.close()
	# 写入完成的更改记录
	fd = open('changeLogs.html', 'w')
	fd.writelines('<html><head><meta charset="utf-8" /></head><body>')
	if len(changeLogs) > 0:
		fd.writelines('<h1>当前的 %s 分支距离上次打包，改动列表如下：</h1>' % (currentBranch.replace('$', '/')))
		fd.writelines(changeLogs)
	else:
		fd.writelines('<h1>首次对 %s 分支打包，或者是出包女王操作失误，反正现在啥也没有。</h1>' % (currentBranch.replace('$', '/')))
	fd.writelines('</body></html>')
	fd.close()
	# 回到原目录
	os.chdir(currdir)

make_all_logs()
print 'logs.py done'
