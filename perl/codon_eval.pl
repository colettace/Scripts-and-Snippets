#!/usr/bin/env perl
use strict;
use warnings;
sub init_codon_count;


my @codons_used;
&init_codon_count;

my @input = <STDIN>;

#chomp( $input );

my $input_seq;
foreach (@input) {
	#print "$_";
	chomp $_;
	$input_seq .= $_;
}

#print $input_seq;

my $seq_len = length( $input_seq );

if( ($seq_len % 3) != 0 ) {
	die "input nucleotide sequence not evenly divisible by 3\n";
}

# make sure the number of nucleotides is divisible by 3
my $num_aa = $seq_len / 3;
print "Amino Acids: $num_aa\n";

# Measure AT/GC percentage
my $GC_percentage = 0;
my $AT_percentage = 0;
my $i;

for( $i = 0; $i < $seq_len; $i++ ) {
	my $nucleotide = substr( $input_seq, $i, 1 );
	if( $nucleotide eq "G" or $nucleotide eq "C" ) {
		$GC_percentage++;
	}
	elsif( $nucleotide eq "A" or $nucleotide eq "T" ) {
		$AT_percentage++;
	}
	else {
		die "nucleotide character \"$nucleotide\" was not {GATC}\n";
	}
}

$GC_percentage /= $seq_len;
$AT_percentage /= $seq_len;

print "%GC=$GC_percentage\t%AT=$AT_percentage\n";

# Count the codons used
my $codon;
for( $i = 0; $i < $num_aa; $i++ ) {
	my $codon = substr( $input_seq, $i*3, 3 );
	#print "$i\t$substr\n";
	my $used = 0;
	foreach (@codons_used) {
		if( $_->{seq} eq $codon ) {
			$_->{count}++;
			$used = 1;
			last;
		}
	}
	if( !$used ) {
		die "Unrecognized codon: $codon\n";
	}
}

print "Codon eval:\n";
my $num_codons_used = 0;

# print out the codon usage statistics in a table that
# is identical to the OPTIMIZER Codon Usage table output
my ($row, $col);
my $count = 0;
for( $row = 0; $row < 16; $row++ ) {
	for( $col = 0; $col < 4; $col++ ) {
		$codon = $codons_used[$count]->{seq};
		print "$codon ";
		my $aa = $codons_used[$count]->{aa};
		print "($aa): ";
		my $the_count = $codons_used[$count]->{count};
		print "$the_count\t";
		if( $the_count != 0 ) {
			$num_codons_used++;
		}
		$count++;
	}
	print "\n";
}

print "num_codons_used: $num_codons_used\n";

sub init_codon_count
{
my $k = 0;
$codons_used[$k]->{seq} = "GCA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "A"; $k++;
$codons_used[$k]->{seq} = "GCC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "A"; $k++;
$codons_used[$k]->{seq} = "GCG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "A"; $k++;
$codons_used[$k]->{seq} = "GCT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "A"; $k++;
$codons_used[$k]->{seq} = "TGC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "C"; $k++;
$codons_used[$k]->{seq} = "TGT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "C"; $k++;
$codons_used[$k]->{seq} = "GAC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "D"; $k++;
$codons_used[$k]->{seq} = "GAT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "D"; $k++;
$codons_used[$k]->{seq} = "GAA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "E"; $k++;
$codons_used[$k]->{seq} = "GAG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "E"; $k++;
$codons_used[$k]->{seq} = "TTC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "F"; $k++;
$codons_used[$k]->{seq} = "TTT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "F"; $k++;
$codons_used[$k]->{seq} = "GGA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "G"; $k++;
$codons_used[$k]->{seq} = "GGC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "G"; $k++;
$codons_used[$k]->{seq} = "GGG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "G"; $k++;
$codons_used[$k]->{seq} = "GGT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "G"; $k++;
$codons_used[$k]->{seq} = "CAC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "H"; $k++;
$codons_used[$k]->{seq} = "CAT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "H"; $k++;
$codons_used[$k]->{seq} = "ATA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "I"; $k++;
$codons_used[$k]->{seq} = "ATC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "I"; $k++;
$codons_used[$k]->{seq} = "ATT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "I"; $k++;
$codons_used[$k]->{seq} = "AAA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "K"; $k++;
$codons_used[$k]->{seq} = "AAG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "K"; $k++;
$codons_used[$k]->{seq} = "TTA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "L"; $k++;
$codons_used[$k]->{seq} = "TTG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "L"; $k++;
$codons_used[$k]->{seq} = "CTA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "L"; $k++;
$codons_used[$k]->{seq} = "CTC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "L"; $k++;
$codons_used[$k]->{seq} = "CTG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "L"; $k++;
$codons_used[$k]->{seq} = "CTT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "L"; $k++;
$codons_used[$k]->{seq} = "ATG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "M"; $k++;
$codons_used[$k]->{seq} = "AAC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "N"; $k++;
$codons_used[$k]->{seq} = "AAT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "N"; $k++;
$codons_used[$k]->{seq} = "CCA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "P"; $k++;
$codons_used[$k]->{seq} = "CCC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "P"; $k++;
$codons_used[$k]->{seq} = "CCG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "P"; $k++;
$codons_used[$k]->{seq} = "CCT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "P"; $k++;
$codons_used[$k]->{seq} = "CAA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "Q"; $k++;
$codons_used[$k]->{seq} = "CAG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "Q"; $k++;
$codons_used[$k]->{seq} = "AGA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "R"; $k++;
$codons_used[$k]->{seq} = "AGG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "R"; $k++;
$codons_used[$k]->{seq} = "CGA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "R"; $k++;
$codons_used[$k]->{seq} = "CGC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "R"; $k++;
$codons_used[$k]->{seq} = "CGG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "R"; $k++;
$codons_used[$k]->{seq} = "CGT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "R"; $k++;
$codons_used[$k]->{seq} = "AGC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "S"; $k++;
$codons_used[$k]->{seq} = "AGT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "S"; $k++;
$codons_used[$k]->{seq} = "TCA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "S"; $k++;
$codons_used[$k]->{seq} = "TCC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "S"; $k++;
$codons_used[$k]->{seq} = "TCG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "S"; $k++;
$codons_used[$k]->{seq} = "TCT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "S"; $k++;
$codons_used[$k]->{seq} = "ACA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "T"; $k++;
$codons_used[$k]->{seq} = "ACC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "T"; $k++;
$codons_used[$k]->{seq} = "ACG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "T"; $k++;
$codons_used[$k]->{seq} = "ACT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "T"; $k++;
$codons_used[$k]->{seq} = "GTA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "V"; $k++;
$codons_used[$k]->{seq} = "GTC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "V"; $k++;
$codons_used[$k]->{seq} = "GTG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "V"; $k++;
$codons_used[$k]->{seq} = "GTT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "V"; $k++;
$codons_used[$k]->{seq} = "TGG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "W"; $k++;
$codons_used[$k]->{seq} = "TAC"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "Y"; $k++;
$codons_used[$k]->{seq} = "TAT"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "Y"; $k++;
$codons_used[$k]->{seq} = "TAA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "."; $k++;
$codons_used[$k]->{seq} = "TGA"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "."; $k++;
$codons_used[$k]->{seq} = "TAG"; $codons_used[$k]->{count} = 0; $codons_used[$k]->{aa} = "."; $k++;
}
