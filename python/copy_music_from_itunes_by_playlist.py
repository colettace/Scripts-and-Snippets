#!/usr/bin/env python
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
			name = attriblist[0].strip().replace( " ", "_") # sometimes has weird spaces added
		except:
			pass

		try:
			artist = attriblist[1].strip().replace( " ", "_") # sometimes has weird spaces added
		except:
			pass
		try:
			album = attriblist[3].strip().replace( " ", "_" )
		except:
			pass
		path_parts =  attriblist[-1].split( ":" )
		# Sometimes need to remove the Machintosh HD

		path = '/' + "/".join( path_parts[1:] )

		# you should have a path that starts with your username
		#path = "/Users/" +path
		if not artist in artist_dict:
			artist_dict[ artist ] = {}
		if not album in artist_dict[ artist ]:
			artist_dict[ artist ][ album ] = {}

		artist_dict[ artist ][ album ][ name ] = path

	itunes_exported_file.close()
	return artist_dict

def CreateArtistDirectories( filepath ):
	
	artist_dict = ParseiTunesExportFile( filepath )

	one_hit_wonders = []
	for artist in artist_dict:
	    if debug: print 'artist:', artist
	    artist_song_count = 0
	    artist_album_count = 0
	    artist_one_offs = []
	    for album in artist_dict[ artist ]:
		if debug: print '\talbum: "', album, '"'
		album_song_count = len( artist_dict[ artist ][ album ] )
		artist_song_count += album_song_count
		if album_song_count <= 3:
		    # add to list of one_offs
		    artist_one_offs += artist_dict[ artist ][ album ]
		else:
		    artist_album_count += 1
		    directory = '/'.join( [ artist, album ] )
		    if not os.path.exists(directory):
			os.makedirs(directory)
		    for song in artist_dict[ artist ][ album ].values():
			if debug: print '\t\tcopying file "', song, '" to directory "', directory, '"'
			try:
			    shutil.copy( song, directory )
			except:
			    if debug: print '\t\t\tPROBLEM COPYING file "', song, '" to directory "', directory, '"'
	    if len( artist_one_offs ) > 0:
		if artist_album_count > 0:
		    # if there was already an album created put the one-offs in a subdir under artist
		    directory = '/'.join( [ artist, "misc" ] )
		    if not os.path.exists(directory):
			os.makedirs(directory)
		    for song in artist_one_offs:
			if debug: print '\t\tcopying file "', song, '" to directory "', directory, '"'
			try:
			    shutil.copy( song, directory )
			except:
			    if debug: print '\t\t\tPROBLEM COPYING file "', song, '" to directory "', directory, '"'
		elif len( artist_one_offs ) >= 3:
		    # just put the one offs in the top level artist directory
		    directory = artist
		    if not os.path.exists( directory ):
			os.makedirs( directory )
		    for song in artist_one_offs:
			if debug: print '\t\tcopying file "', song, '" to directory "', directory, '"'
			try:
			    shutil.copy( song, directory )
			except:
			    if debug: print '\t\t\tPROBLEM COPYING file "', song, '" to directory "', directory, '"'
		else:
		    # not enough songs, put in list of one hit wonders
		    one_hit_wonders += artist_one_offs
	 
	directory = 'one_hit_wonders'
	print "\n\n"
	print directory
	if not os.path.exists( directory ):
	    os.makedirs( directory )
	for song in one_hit_wonders:
	    if debug: print '\t\tcopying file "', song, '" to directory "', directory, '"' 
	    try:
		shutil.copy( song, directory )
	    except:
		if debug: print '\t\t\tPROBLEM COPYING file "', song, '" to directory "', directory, '"' 


def CreatePlaylistDirectory( playlist_file ):
	artist_dict = ParseiTunesExportFile( playlist_file )

	directory = playlist_file + '_dir'
	if not os.path.exists( directory ):
		os.makedirs( directory )
	for artist in artist_dict:
		albums = artist_dict[ artist ]
		for album_name in albums:
			songs = albums[ album_name ]
			for song_name in songs:
				song_path = songs[ song_name ]
				if song_path.endswith( ('mp3', 'MP3') ):
					suffix = 'mp3'
				elif song_path.endswith( ( 'm4a', 'M4A', 'm4p' ) ):
					suffix = 'm4a'
				else:
					print "*****************WHAT SUFFIX? ", song_path
					continue
					
				try:
					new_name = directory + os.sep + '{}--{}--{}.{}'.format( artist, album_name, song_name, suffix )
					if debug: print song_path, '------>', new_name
					shutil.copy( song_path, new_name )
				except:
					if debug: print '****************PROBLEM COPYING', song_path
	
	


	
if __name__ == '__main__':

	filepath = sys.argv[1]
	CreatePlaylistDirectory( filepath )



