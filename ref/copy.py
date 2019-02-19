# -*- coding:utf-8 -*- 
import sys
import os
import time
from shutil import copy2
from shutil import copytree

disableLog = True # 屏蔽自定义Log
needCreate = True # 是否需要创建不存在的目标文件夹
srcPath = None
dstPath = None

def customPrint(log):
	if not disableLog:
		print(log)

def resourceSearch(rootDir, srcName, dstName, needCreate):
	global dstPath
	global srcPath
	for path in os.listdir(rootDir):
		fullPath = os.path.join(rootDir, path)
		if os.path.isdir(fullPath):
			if path == dstName:
				dstPath = fullPath
			elif path == srcName:
				srcPath = fullPath
		if srcPath != None and dstPath != None:
			break
	if needCreate and dstPath == None:
		dstPath = os.path.join(rootDir, dstName)
		os.mkdir(dstPath)

def resourceCopy(srcDir, dstDir):
	for path in os.listdir(srcDir):
		fullSrcPath = os.path.join(srcDir, path)
		fullDstPath = os.path.join(dstDir, path)
		if path == 'Info.plist':
			continue
		elif os.path.isdir(fullSrcPath):
			if not os.path.exists(fullDstPath):
				customPrint('    Copying folder: %s' % path)
				copytree(fullSrcPath, fullDstPath)
			elif os.path.isdir(fullDstPath):
				resourceCopy(fullSrcPath, fullDstPath)
		elif os.path.isfile(fullSrcPath):
			if not os.path.exists(fullDstPath):
				customPrint('    Copying file: %s' % path)
				copy2(fullSrcPath, fullDstPath)
			elif os.path.isfile(fullDstPath):
				if os.path.getmtime(fullSrcPath) != os.path.getmtime(fullDstPath):
					customPrint('    Overwriting file: %s' % path)
					copy2(fullSrcPath, fullDstPath)


for argv in sys.argv:
	print(argv)
if len(sys.argv) > 4 and sys.argv[4] == '0':
	needCreate = False
resourceSearch(sys.argv[1], sys.argv[2], sys.argv[3], needCreate)
if srcPath == None:
	raise Exception('Cannot find source path.')
if dstPath == None:
	raise Exception('Cannot find or create destination path.')
print('Source Path: %s' % (srcPath))
print('Destination Path: %s' % (dstPath))
print('Start copying...')
startTime = time.time()
resourceCopy(srcPath, dstPath)
print('Finish copying. Cost time: %.2fs' % (time.time() - startTime))
