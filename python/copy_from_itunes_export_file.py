#!/usr/bin/env python
"""This can be kind of a pain in the ass due to filenames being encoded in UTF-16"""
import os
import shutil
import io
import sys
 
filepath = sys.argv[1]
itunes_exported_file = io.open( filepath, 'r',encoding='utf-16')
 
artist_dict = {}
linenum = 0
for line in itunes_exported_file:
    linenum += 1
    if linenum == 1:
        continue # Skip the column headers
    #Name, Artist, Composer, Album, Grouping, Genre, Size, Time, DiscNum, DiscCount, TrackNumber, TrackCount, Year, DateModified, DateAdded, BitRate, SampleRate, VolumeAdjustment, Kind, Equalizer, Comments, Plays, LastPlayed, Skips, LastSkipped, MyRating, Location = line.strip().split( "\t" )
    attriblist = line.strip().split( "\t" )
    try:
        artist = attriblist[1].strip().replace( " ", "_") # sometimes has weird spaces added
    except:
        pass
    try:
        album = attriblist[3].strip().replace( " ", "_" )
    except:
        pass
    path_parts =  attriblist[-1].split( ":" )
    path = "/".join( path_parts )
    # you should have a path that starts with your username
    path = "/Users/" +path
 
    if not artist in artist_dict:
        artist_dict[ artist ] = {}
    if not album in artist_dict[ artist ]:
        artist_dict[ artist ][ album ] = []
 
    artist_dict[ artist ][ album ].append( path )
 
itunes_exported_file.close()
 
debug = True
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
            for song in artist_dict[ artist ][ album ]:
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
