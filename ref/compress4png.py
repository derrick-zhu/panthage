# -*- coding:utf-8 -*- 
import sys,os
import shlex,subprocess
import time

totalSave = 0
rootPath = ''

def do_shell(COMMAND):
	subprocess.call(shlex.split(COMMAND))

exclude_paths = [
	'Carthage/Checkouts/ijkplayer',
	'Carthage/Checkouts/BFC/Components/BFCShare/BFCShare/Share/SocialSharing/sdk'
]
def compress4Png(DIR):
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
			compress4Png(fullPath)
		elif os.path.isfile(fullPath):
			if path.lower().endswith('.png'):
				do_shell('./pngquant --ext .png.tmp "%s"' % (fullPath))
				tmpPath = fullPath + '.tmp'
				if os.path.isfile(tmpPath):
					originalSize = os.path.getsize(fullPath)
					newSize = os.path.getsize(tmpPath)
					if newSize < originalSize * 0.9 and originalSize - newSize > 10240:
						global totalSave
						totalSave = totalSave + (originalSize - newSize)
						print('%s: -%dKB, %.0f%%' % (fullPath.replace(rootPath, ''), (originalSize - newSize) / 1024, newSize * 100.0 / originalSize))
						do_shell('rm "%s"' % (fullPath))
						do_shell('mv "%s" "%s"' % (tmpPath, fullPath))
					else:
						do_shell('rm "%s"' % (tmpPath))

startTime = time.time()
if len(sys.argv) > 1:
	rootPath = sys.argv[1]
else:
	rootPath = sys.path[0]
compress4Png(rootPath)
print('Done. Save %dKB. Cost: %.2fs' % (totalSave / 1024, time.time() - startTime))
