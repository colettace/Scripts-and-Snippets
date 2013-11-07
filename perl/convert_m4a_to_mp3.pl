#!/usr/bin/env perl

use warnings;
use strict;

my @files = `find . -name "*.m4a"`;
foreach (@files) {
	chomp;
	print $_ . "\n";
	my $newname = $_;
	my $orig = $_;
	$newname =~ s/m4a/mp3/;
	print $newname . "\n";
	my $cmd = "faad -o - \"$orig\" | lame - \"$newname\"";
	print $cmd . "\n";
	system( $cmd );
	unlink( $orig );
}
1;

