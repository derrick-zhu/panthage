# -*- coding:utf-8 -*- 
import re
import sys,os
import cgi
try:
	import bili_mail
except:
	pass
from termcolor import colored

text = ''
html = ''
warningCount = 0
errorCount = 0
onServer = False

def addText(TEXT):
	if onServer == False:
		print TEXT
	else:
		global text
		global html
		text = text + TEXT + '\n'
		html = html + '<p>%s</p>' % (cgi.escape(TEXT))

def addWarning(TEXT):
	global warningCount
	warningCount = warningCount + 1
	if onServer == False:
		print colored(TEXT, 'magenta')
	else:
		global text
		global html
		text = text + TEXT + '\n'
		html = html + '<p><span style=\"color:#FF00FF\">%s</span></p>' % (cgi.escape(TEXT))

def addError(TEXT):
	global errorCount
	errorCount = errorCount + 1
	if onServer == False:
		print colored(TEXT, 'red')
	else:
		global text
		global html
		text = text + TEXT + '\n'
		html = html + '<p><span style=\"color:#FF0000\">%s</span></p>' % (cgi.escape(TEXT))

def addLink(TEXT):
	if onServer == False:
		print colored(TEXT, 'blue')
	else:
		global text
		global html
		text = text + TEXT + '\n'
		html = html + '<p><a href="%s">%s</a></p>' % (TEXT, TEXT)

def getProjectAndFileName(FILEPATH):
	paths = FILEPATH.split('/')
	fileName = paths[-1]
	project = '???'
	for index in range(len(paths)):
		if paths[index - 1] == 'contrib':
			project = paths[index]
			break
	return '<%s> %s' % (project, fileName)

delegatePattern = re.compile(r'@property\s*\(([\w\s,]+)\)[\w\s<>\*_]+[dD]elegate\s*;(.*)')
def scan_weakDelegate(CONTENT, FILEPATH):
	match = delegatePattern.search(CONTENT)
	while match:
		if 'weak' not in match.group(1) and 'SCANNER_IGNORE' not in match.group(2):
			addWarning(getProjectAndFileName(FILEPATH) + ': 没有为delegate使用weak修饰词')
			addText(match.group(0))
		match = delegatePattern.search(CONTENT, match.end() + 1)

exclude_paths = [
	'Carthage/Checkouts/BBPhoneBase',
	'Carthage/Checkouts/ijkplayer',
	'Carthage/Checkouts/BiliCore/BiliCore/Player/IJKMedia',
	'Carthage/Checkouts/BFC/Components/BFCShare/BFCShare/Share/SocialSharing/sdk',
	'Carthage/Checkouts/BiliCore/BiliCore/3rd/Bugly',
	'Carthage/Checkouts/BiliUtils/PodLinker'
]
exclude_prefixs = [
	'GPUImage',
	'RAC'
]
def scan_code(DIR):
	for path in os.listdir(DIR):
		fullPath = os.path.join(DIR, path)
		if os.path.isdir(fullPath):
			needSkip = False
			for exclude_path in exclude_paths:
				if exclude_path in fullPath:
					needSkip = True
					break
			if needSkip:
				continue
			scan_code(fullPath)
		elif os.path.isfile(fullPath):
			needSkip = False
			for exclude_prefix in exclude_prefixs:
				if path.startswith(exclude_prefix):
					needSkip = True
					break
			if needSkip:
				continue
			if path.lower().endswith('.m') or path.lower().endswith('.h'):
				codeFile = open(fullPath, 'r')
				content = codeFile.read()
				codeFile.close()
				scan_weakDelegate(content, fullPath)

def main():
	global onServer
	# 如果是编译机，可以带上安装链接
	if os.path.isfile('./builder/output/bili-universal/install.txt'):
		onServer = True
		installFile = open('./builder/output/bili-universal/install.txt', 'r')
		content = installFile.read()
		installFile.close()
		addText('==== 安装页二维码 ====')
		addLink(content)
		addText('')
	# 静态扫描各类问题
	addText('==== 静态扫描日志 ====')
	scan_code(os.getcwd())
	addText('%d个错误，%d个警告' % (errorCount, warningCount))
	if errorCount + warningCount > 0:
		addText('对于需要忽略的错误和警告，请在行尾添加注释：SCANNER_IGNORE')
	addText('静态扫描结束')
	# send_mail(TEXT, HTML, SUBJECT = '来自iOS编译机的邮件', TO_LIST = ['xihaoyang@bilibili.com'])
	if onServer:
		bili_mail.send_mail(text, html, 'iOS粉版主干每日自动编译报告', [\
			'xihaoyang@bilibili.com',\
			'zhangxinzheng@bilibili.com',\
			'zhangtao@bilibili.com',\
			'zhangyuhang@bilibili.com',\
			'zhangyaoqi@bilibili.com',\
			'kuangchaodan@bilibili.com',\
			'gengyue@bilibili.com',\
			'huangxiaoyong@bilibili.com',\
			'gonghaiyan@bilibili.com',\
			'zhufan@bilibili.com',\
			'wangyisha@bilibili.com',\
			'zhangjun@bilibili.com'\
		])

if __name__ == '__main__':
	main()
