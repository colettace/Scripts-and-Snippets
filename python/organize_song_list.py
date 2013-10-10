"""
A script to convert my html song list into wikitable format.
"""

from collections import OrderedDict
import re
p1 = re.compile( r'<tr class="out"><td class="year">(.+?)</td><td>(.+?)</td><td>(.+?)</td></tr>' )
p2 = re.compile( r'</td></tr>(-->)?<!--(.+)-->$' )
h2 = re.compile( r'<h2>(.+?)</h2>' )

class Song( object ):
	tables = OrderedDict()
	def __init__(self):
		self.year = None
		self.name = None
		self.band = None
		self.in_rotation = True
		self.notes = None
	
	@classmethod
	def GenerateWikitable( cls, in_rotation = True ):

		# begin table
		text = '{| class="wikitable sortable"\n'

		# Add Caption
		wishes = " performs."
		if not in_rotation:
			wishes = ' used to perform or wishes he could perform.'

		text += '|+ A table of all the songs Chris' + wishes + '\n'

		# Add Column headers
		column_headers = """! scope="col" | Year
! scope="col" | Song Name
! scope="col" | Band
! scope="col" | Notes
"""
		text += column_headers

		for tablename in cls.tables:
			table_header = """|- class="sortbottom"
| colspan="5" align="center" style="background: #FAF0E6;" | """ + tablename + '\n'
			added_tableheader = False 

			for song in cls.tables[ tablename ]:
				if song.in_rotation == in_rotation:
					if not added_tableheader:
						text += table_header
						added_tableheader = True
					notes = song.notes if song.notes else ''
					text += '|-\n'
					text += '| ' + song.year + ' || ' + song.name + ' || ' + song.band + \
									' || ' + notes + '\n'

		text += '|-\n' + column_headers
		# end table
		text += '|}\n'
		return text

if __name__ == '__main__':
	tablename = None
	current_table = None
	with open( 'song_list.html' ) as songfile:
		for line in songfile:
			# Keep track of which song is coming from which table
			if '<h2>' in line:
				m = h2.search( line )
				if not m:
					raise Exception( line )
				tablename = m.groups()[0]
				if tablename not in Song.tables:
					Song.tables[ tablename ] = []
				current_table = Song.tables[ tablename ]

			if '<tr class="out">' in line:
				song = Song()
				if line.startswith( '<!--' ):
					song.in_rotation = False
				m = p1.search( line )
				if not m:
					raise Exception( line )
				info = m.groups()
				print info
				song.year = info[0]
				song.name = info[1]
				song.band = info[2]
				m = p2.search( line )
				if m:
					song.notes = m.groups()[-1]
					print 'Notes found:', song.notes
				current_table.append( song )

	print Song.GenerateWikitable()
	print Song.GenerateWikitable(False)
