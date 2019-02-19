# -*- coding:utf-8 -*- 
import sys
import os
import time
from shutil import copy2

def copyPng(srcDir, dstDir, name):
	print('search file: ' + name)
	for path in os.listdir(srcDir):
		fullSrcPath = os.path.join(srcDir, path)
		if os.path.isfile(fullSrcPath):
			if path.lower().endswith('.png') and path.startswith(name):
				if path[len(name)] == '.' or path[len(name)] == '@' or path[len(name)] == '~':
					fullDstPath = os.path.join(dstDir, path)
					copy2(fullSrcPath, fullDstPath)
					print('copy file: ' + fullDstPath)

def pdf2png(srcDir, dstDir, name = ''):
	for path in os.listdir(dstDir):
		fullDstPath = os.path.join(dstDir, path)
		if os.path.isdir(fullDstPath):
			pdf2png(srcDir, fullDstPath, path)
		elif os.path.isfile(fullDstPath):
			if path.lower().endswith('.pdf') and name.lower().endswith('.imageset'):
				os.remove(fullDstPath)
				print('remove file: ' + fullDstPath)
				copyPng(srcDir, dstDir, name[0:-9])

# 输入参数1: 包含所有png图片的目录，例如以前的ipa解压出来的文件夹，模拟器上编译出ios-unversal.app文件夹
# 输入参数2: 需要检查的image assets目录
startTime = time.time()
pdf2png(sys.argv[1], sys.argv[2])
print('Done. Cost time: %.2fs' % (time.time() - startTime))
