
"""
stats.py

Get information about classes for the evaluation. 

author : Xavier Devroey <x.d.m.devroey@tudelft.nl>
"""

import sys
import re
import csv
import statistics


####################
# Functions
####################

def usage():
	print('usage: stats.py <subjects.csv> <output.csv>')

####################
# Main program
####################


if len(sys.argv) < 2:
	print('Wrong number of arguments!')
	usage()
	exit()


with open(sys.argv[1], 'r') as subjects, open(sys.argv[2], 'w') as output:
	fieldnames = ['project_id', 'bug_id', 'class', 'method', 'ncss_class', 'ncss_method', 'ccn']
	writer = csv.DictWriter(output, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL, fieldnames=fieldnames)
	writer.writeheader()
	for line in csv.DictReader(subjects):
		# target_class, project_id, bug_id
		cut = line['target_class']
		ccnFile = 'buggy-versions' + '/' + line['project_id'] + '-' + line['bug_id'] + '/' + 'ccn.txt'
		stats = dict()
		stats['project_id'] = line['project_id']
		stats['bug_id'] = line['bug_id']
		stats['class'] = cut
		with open(ccnFile, 'r') as ccnIn:
			for line in ccnIn:
				m1 = re.match(r"^[ \t]*(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(.+)$", line)
				m2 = re.match(r"^[ \t]*(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(\d+)[ \t]+(.+\))$", line)
				if m1 :
					# Nr. NCSS Functions Classes Javadocs Class
					#   2  474        40       0       41 org.jfree.chart.ChartFactory
					clazz = m1.group(6)
					if clazz == cut:
						print('Found class {}'.format(clazz))
						stats['ncss_class'] = int(m1.group(2))
				elif m2 :
					# Nr. NCSS CCN JVDC Function
					#    1   13   1    0 com.alibaba.fescar.core.message.CodecTest.testA()
					method = m2.group(5)
					if method.startswith(cut + '.'):
						print('Found method {} of class {}'.format(method, cut))
						stats['method'] = method
						stats['ncss_method'] = int(m2.group(2))
						stats['ccn'] = int(m2.group(3))
						writer.writerow(stats)
