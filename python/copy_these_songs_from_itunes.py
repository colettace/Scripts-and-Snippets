import os
import shutil
import io
import sys

debug = True

def ParseiTunesExportFile( filepath ):
	itunes_exported_file = io.open( filepath, 'r', encoding='utf-16')

	artist_dict = {}
	linenum = 0
	for line in itunes_exported_file:
		linenum += 1
		if linenum == 1:
			continue # Skip the column headers
		#Name, Artist, Composer, Album, Grouping, Genre, Size, Time, DiscNum, DiscCount, TrackNumber, TrackCount, Year, DateModified, DateAdded, BitRate, SampleRate, VolumeAdjustment, Kind, Equalizer, Comments, Plays, LastPlayed, Skips, LastSkipped, MyRating, Location = line.strip().split( "\t" )
		attriblist = line.strip().split( "\t" )
		try:
			name = str(attriblist[0].strip()).lower()
		except:
			continue
		try:
			artist = str(attriblist[1].strip()).lower()
			if artist.startswith('the'):
				artist = artist[4:]
		except:
			continue

		path_parts =  attriblist[-1].split( ":" )
		# Sometimes need to remove the Machintosh HD

		path = '/' + "/".join( path_parts[1:] )

		if artist not in artist_dict:
			artist_dict[artist]=[]
		artist_dict[artist].append( ( str(name), path ))

	itunes_exported_file.close()
	return artist_dict

def ParseMySet( ):
	import re
	p = re.compile( r'^\| \S+ \|\| (.+) \|\| (.+) \|\|' )
	q = re.compile('[\/\\\(\)]' )
	artist_dict = {}
	with open( 'myset.txt' ) as _file:
		for line in _file:
			m = p.match(line)
			if m:
				name = m.groups()[0].replace('&amp;','&').lower()
				artists = m.groups()[1].replace('&amp;','&').lower()
				for artist in filter(None,q.split(artists)):
					_artist = artist.strip()
					if _artist.startswith('the'):
						_artist = _artist[4:]
					if _artist not in artist_dict:
						artist_dict[_artist]=[]
					artist_dict[_artist].append(name)
	return artist_dict
					

if __name__ == '__main__':
	import shutil
	filepath = sys.argv[1]
	itunes_dict = ParseiTunesExportFile( filepath)
	my_dict = ParseMySet()

	found_songs = []
	lost_songs = []
	lost_artists = []
	for myartist in my_dict:
		foundartist = False
		for itartist in itunes_dict:
			if myartist in itartist:
				foundartist = True
				# look for song overlap
				for mysong in my_dict[myartist]:
					foundsong = False
					for itsong in itunes_dict[itartist]:
						if mysong in itsong[0]:
							foundsong = True
							found_songs.append(itsong[1])
							try:
								shutil.copy( itsong[1], '/Volumes/PLAYLISTS/my_setlist' )
							except:
								print "******PROB copying ", itsong[1]
					if not foundsong:
						lost_songs.append( myartist + ': ' + mysong)
		if not foundartist:
			lost_artists.append( myartist )

	print '======================================FOUNDDDDDDDDDDDDDDDDD'
	for path in sorted(found_songs):
		print path
	print len( found_songs)

	print'\n\n\n==LLLOOOOOOSSSSSSSSTTTTTTTTTTTTTTT++++++++++++++'
	for name in sorted(lost_songs):
		print name
	print len(lost_songs)

	print'\n\n\n==LLLOOOOOOSSSSSSSSTTTTTTTTTTTTTTT++++++++++++++'
	for name in sorted(lost_artists):
		print name
	print len(lost_artists)

