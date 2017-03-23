#!/usr/bin/perl
use strict;
use warnings;
require HTML::Tree;
require Statistics::Descriptive;
require Statistics::KernelEstimation;

use Getopt::Long;
my $num_bins = undef;
#my $bin_width = undef;
my $normalize = undef;
my $num_classes = undef;
my $flags = undef;
my $bandwidth = undef;
my $input_file = undef;
my $interp_val_dump_file = undef;
my $verbose = undef;
my $tolerance = 0.1; # Used for marginal probability analysis.
                     # Represents % deviation from 1/n that defines if an
                     # image was classified as random, i.e.,
                     # 1/n +/- $tolerance marginal probabilities across all classes

my $stats_only = undef; # Skip the ks density graphs

GetOptions( "bins=i"  => \$num_bins,
           # "window_size=f" => \$bin_width,
            "normalize=s" => \$normalize,
            "num_classes=i" => \$num_classes,
            "flags=i" => \$flags,
            "bandwidth=s" => \$bandwidth,
            "input_file=s" => \$input_file,
            "dump_interp_vals=s" => \$interp_val_dump_file,
            "verbose=i" => \$verbose,
            "stats_only=i" => \$stats_only, 
            "tolerance=f" => \$tolerance );

print "Histogram will be created with number of bins: $num_bins\n" if( defined $num_bins );
#print "Window size : $bin_width\n" if( defined $bin_width );
print "Age scores will be normalized\n" if( defined $normalize );

$verbose = $stats_only if $stats_only ;

my %results_hash;
my $min = -1;
my $max = -1;
my $interpolated_value;
my $predicted_class;
my $split_number;
my $normalized_distances;

if( !defined $input_file )
{
# Takes a wndchrm output html file as input.
# HTML file should have been procured as part of a wndchrm test operation
# where the operation derives interpolated values

# This code parses html output file, and counts how many images in the test set were
# sorted into the given bins.
  my $output_file = shift;

  print "Loading $output_file\n";
  my $tree = HTML::TreeBuilder->new_from_file( $output_file );
  print "Done loading $output_file\n";

#$tree->dump; 
  my @table_elements = $tree->look_down("_tag", "TABLE", 
       sub
       {
         if( defined $_[0]->attr("ID") ) {
           if( $_[0]->attr("ID") =~ /IndividualImages_split/ ) {
             # print "Got one!\n";
             return 1;
           }
         }
         # print "DON' GOT ONE!!\n";
         return 0;
       }
     );

  die "Couldn't find the test results table element in file $output_file\n" if( !@table_elements );
# print "Number of splits found: $#table_elements\n";

# print "step one: figure out the number of classes\n\n";
  if( !defined $num_classes ) {
    my $class_structure_elem = $tree->look_down("_tag", "table");
    die "Couldn't derive number of classes from html file $output_file.\n" if( !$class_structure_elem );

    # print $class_structure_elem->as_HTML . "\n";

    # Grab the first row that doesn't contain the caption
    my $first_row = $class_structure_elem->look_down( "_tag", "tr", sub{ not $_[0]->look_down( '_tag', 'caption' ) } );
    die "Couldn't derive number of classes from html file $output_file.\n" if( !$first_row );

#print $first_row->as_text . "\n";

    my @class_rows = $first_row->look_down("_tag", "td");
    $num_classes = $#class_rows - 1;
  }
  print "Number of classes used: $num_classes\n";

  my @rows;
  my @row;
#  my %results_hash;
  my $val;
  my $img_link_element;
  my $fullpath;
  my $filename;
  my $actual_class;
  my $DEBUG1 = 0;

  #my $min = -1;
  #my $max = -1;
  my $image_column;

  foreach my $split_table_element (@table_elements)
  {
    @rows = $split_table_element->look_down("_tag", "tr");

    # print "Parsing $output_file, " . $split_table_element->attr("ID") ."\n";
    if( $split_table_element->attr("ID") =~ /IndividualImages_split(\d+)/ ) {
      $split_number = $1;
    }
    else {
      $split_number = -1;
    }


    # Parse the first "Caption" row
    @row = $rows[0]->look_down("_tag", "th");
		if( $#row == -1 ) {
    	print "Old style <td><b>..</b></td> column headers detected\n\n" if( $DEBUG1 );
    	@row = $rows[0]->look_down("_tag", "td");
		}
# Make sure there are interpolated values to read out of html report

		if( !$stats_only ) {
			my $interp_val_col_exists = 0;
			foreach (@rows){
				if( $_->as_text =~ /interpolated/i ) {
					$interp_val_col_exists = 1;
					last;
				}
			}
			if( !$interp_val_col_exists ) {
				die "*****************\nERROR: The HTML report file $output_file doesn't appear to have a column of interpolated values in the
	individual image predictions table! Please rerun wndchrm, changing the names of the classes such that
	they can be interpreted as numbers and an interpolated value can be calculated.\n\n";
			}
		}

    my $caption_text = $row[$#row]->as_text;
    if( $caption_text =~ /Most similar image/ ) {
      $image_column = $#row - 1;
    } else {
      $image_column= $#row;
    }
    if( defined $flags && $flags =~ /1/ ) {
# weird wndchrm report discrepancy, use second row when column headers don't match up.
      @row = $rows[1]->look_down("_tag", "td");
      $image_column= $#row;
    }  if( defined $flags && $flags =~ /2/ ) {
# weird wndchrm report discrepancy, use second row when column headers don't match up.
      @row = $rows[1]->look_down("_tag", "td");
      $image_column= $#row - 1;
    }

    print "Image column is $image_column\n\n" if( $DEBUG1 );


# Skip the first row which contains column headers
		for( my $i = 1; $i <= $#rows; $i++) {
      $val = 0;
      @row = ();
      $img_link_element = undef;
      @row = $rows[$i]->look_down("_tag","td");
      if( $DEBUG1 ) {
        foreach (@row) {
          print "  " . $_->as_text;
        }
        print "\n";
      }
      $img_link_element = $row[$image_column]->look_down( "_tag", "A" );
      $fullpath = $img_link_element->attr("HREF");
      if( $fullpath =~ /\S*\/(\S+)/ ) {
        $filename = $1;
#      print "\tFound file $filename\n";

        $normalized_distances = "";
        # Skip the first two columns, which should be the Image No. and the Normalization Factor
        for( my $j = 2; $j <= ( 2 + $num_classes ); $j++ ) {
          $normalized_distances .= $row[$j]->as_text . "  ";
        }
        $actual_class = $row[ $image_column - 4 ]->as_text;
        $predicted_class = $row[ $image_column - 3 ]->as_text;
				if( !$stats_only ) {
					$interpolated_value = $row[ $image_column - 1 ]->as_text;
					if( $min == -1 ) {
						$min = $interpolated_value;
					}
					$min = $interpolated_value if( $interpolated_value < $min );
					if( $max == -1 ) {
						$max = $interpolated_value;
					}
					$max = $interpolated_value if( $interpolated_value > $max );
				}
        print "\t\tactual: $actual_class, predicted: $predicted_class, interp val: $interpolated_value\n" if( $DEBUG1 );
        push @{ $results_hash{ $actual_class }->{ $filename } }, { "split_num" => $split_number, "val" => $interpolated_value, "class" => $predicted_class, "dists" => $normalized_distances };
      }
    }
  }
  $tree->delete();
}
else
# if input file is specified, we're skipping over the wndchrm html part and inputting
# marginal probabilities directly, in the form of some tab separated file
{
  open INPUT, $input_file;
  #my $num_images_per_class = 180;
  # my $num_classes = 7;
  my $current_class;
  my $img_name;
  my @normalized_distances_ary;
  #my @coeff_ary = (3.19, 5.53, 11.42, 13.01, 19.22, 21.40, 25.12);
  my @coeff_ary = (0,2,4,6,8,10,12);
	$num_classes = 1+ $#coeff_ary;
  my %data; 

  my $old_chomp = $/;
	$/ = "\r\n";
  my $count = 0;
  while (<INPUT>)
  {
		chomp;

		next if 1 == ++$count;

    @normalized_distances_ary = ();

    $interpolated_value = 0;
		@normalized_distances_ary = split "\t", $_;
	
		$img_name = shift @normalized_distances_ary;
		$current_class = shift @normalized_distances_ary;
		
		#@{ $data{ $ground_truth_class }->{$img_name} } = @line;
#    $interpolated_value = 0;
#    $current_class = "class" . int( $count / $num_images_per_class );
#    $img_name = "image" . $count;
#    @normalized_distances_ary = split /\s+/, $_;
#    die "num classes ($num_classes) does not equal num distances ($#normalized_distances_ary)\n"
#      if( $#normalized_distances_ary != $num_classes -1 );
#    
    for( my $j = 0; $j <= $#normalized_distances_ary; $j++) {
      print "\t\tinterp val $interpolated_value +=  $normalized_distances_ary[$j] * $coeff_ary[$j]\n";
      $interpolated_value += $normalized_distances_ary[$j] * $coeff_ary[$j];
    }

    print "$current_class $img_name interp val $interpolated_value\n";
    if( $min == -1 ) {
      $min = $interpolated_value;
    }
		else {
    	$min = $interpolated_value if( $interpolated_value < $min );
		}

    if( $max == -1 ) {
      $max = $interpolated_value;
    }
		else {
    	$max = $interpolated_value if( $interpolated_value > $max );
		}
   push @{ $results_hash{ $current_class }->{ $img_name} }, {
       "split_num" => 1, "dists" => ( join " ", @normalized_distances_ary ), "val" => $interpolated_value, "class" => -1 };
    $count++;
  }

#	foreach $ground_truth_class ( keys %data ) {
#		foreach $img_name ( keys %{ $data{ $ground_truth_class} } ) {
#			print "GT " . $ground_truth_class . " name " . $img_name . " ";
#			foreach (	@{ $data{ $ground_truth_class }->{$img_name} } ) {
#				print $_ . " ";
#			}
#			print "\n";
#		}
#	}
	$/ = $old_chomp;
  close INPUT;
}

my $range = $max - $min;
my @interp_vals;
my $stat = Statistics::Descriptive::Sparse->new();
my $norm_stat = Statistics::Descriptive::Sparse->new();
my $class_stat = Statistics::Descriptive::Full->new();
my $ks_class_stat = Statistics::KernelEstimation->new();
my $report;
my $histogram;
my $PDF;
my $distribution_hash;

# These are variables concerned with determining whether or not the image was classified ambiguously
my $random_marg_prob = 1 / $num_classes;
my $marg_prob_tolerance = $tolerance * $random_marg_prob;

open( INTERP_VAL_DUMP_FILE, '>', $interp_val_dump_file ) if( defined $interp_val_dump_file );

print "RESULTS:\n" if( $verbose );
foreach my $class ( sort keys %results_hash ) {
	#print "\tClass \"$class\"\n" if( $verbose );
  foreach my $file ( sort keys %{ $results_hash{ $class } } ) {
    @interp_vals = ();
    #print "\t\tFile \"$file\"\n" if( $verbose );
    $stat->clear;
    $norm_stat->clear;
    foreach my $hash_ref ( @{ $results_hash{ $class }->{ $file } } ) {
      $interpolated_value = $hash_ref->{ "val" };
      $normalized_distances = $hash_ref->{ "dists" };
      $predicted_class = $hash_ref->{ "class" };
      $split_number = $hash_ref->{ "split_num" };

      # You do not want to take into account images that the classifier can't classify.
      # The way you tell is that all the marginal probabilities are 1/n, n being the number of classes.
      my $ambiguous_split = 1;
      if( $tolerance > 0 )
      {
        foreach ( split /\s+/, $normalized_distances )
        {
          # if you have a single marginal probability that's outside the "dead zone"
          # of 1/n +/- %10, then this image is fine.
          if( $_ < ($random_marg_prob - $marg_prob_tolerance) or 
              $_ > ($random_marg_prob + $marg_prob_tolerance) )
          {
            $ambiguous_split = 0;
            last;
          }
        }
      }
      if( $ambiguous_split and $tolerance > 0 )
      {
        # Report it, but don't count it.
        #printf( "\t\t\tsplit %2.d - predicted: $predicted_class, actual: $class. Norm dists: ( $normalized_distances) Interp val: $interpolated_value *SKIPPED*\n", $split_number) if( $verbose );
      }
      else
      {
        # Report it AND count it.
				if( !$stats_only ) {
					$stat->add_data( $interpolated_value );
					$norm_stat->add_data( ( $interpolated_value - $min ) / $range );
				}
				else {
					$stat->add_data( -1 );
					$norm_stat->add_data( -1 );
				}
        if( $stats_only ) {
					#printf( "\t\t\tsplit %2.d - predicted: $predicted_class, actual: $class. Norm dists: ( $normalized_distances)\n", $split_number);
				}
				elsif ($verbose) {
        	#printf( "\t\t\tsplit %2.d - predicted: $predicted_class, actual: $class. Norm dists: ( $normalized_distances) Interp val: $interpolated_value\n", $split_number);
				}
      }
    } # end iterating over each image's split result

    if( not $stat->count > 0  )
    {
      print "\t\t\t********SKIPPING THIS IMAGE DUE TO AMBIGUOUS CLASSIFICATION**************\n" if( $verbose );
    }
    else
    {
      print( "$class\t$file\t" . $stat->count . "\t". $stat->mean . "\t" . $stat->standard_deviation . "\n" );
	#%d times, mean %.3f, std dev %.3f. Normalized to [0,1]: mean: %.4f, std_dev: %.4f\n",
        #$stat->count, $stat->mean, $stat->standard_deviation, $norm_stat->mean, $norm_stat->standard_deviation ) if( $verbose ); 
      if( defined $normalize ) # Report the interpolated values on the [0,1] interval
      {
        $class_stat->add_data( $norm_stat->mean );
        $ks_class_stat->add_data( $norm_stat->mean );
        print INTERP_VAL_DUMP_FILE $class . "," . $norm_stat->mean . "\n" if( defined $interp_val_dump_file );
      }
      else # Normal reporting of values
      {
        $class_stat->add_data( $stat->mean );
        $ks_class_stat->add_data( $stat->mean );
        print INTERP_VAL_DUMP_FILE $class . "," . $stat->mean . "\n" if( defined $interp_val_dump_file );
      }
    }
    #print "\n" if( $verbose );
  } # end iterating over each image
  $class_stat->sort_data;
  $report .= sprintf "Class $class: count= %3d, min=%.4f, max=%.4f, mean=%.4f, std dev=%.4f, ", 
               $class_stat->count, $class_stat->min, $class_stat->max, $class_stat->mean, $class_stat->standard_deviation;

  # Here is the old code which simply constructs a histogram
  if( defined $num_bins ) {
    $distribution_hash = $class_stat->frequency_distribution_ref($num_bins);
    $histogram .= "Class $class\n";
    foreach( sort {$a <=> $b} keys %$distribution_hash ) {
      $histogram .= "$_\t$distribution_hash->{$_}\n";
    }
    # End generation of histogram for this class
  }
  else {
		if( !$stats_only ) {
			# Begin new code generating PDF using kernal smoothing for this class
			print "\nClass $class\n";
			$PDF .= "\nClass $class\n";

			my $bw;
			my $obw;
			# always output default bandwidth, even if it's specified on command line
			$bw = $ks_class_stat->default_bandwidth();
			print "\tDefault bandwidth is $bw\n";
			$report .= "bandwidth=$bw\n";
			if( defined $bandwidth && $bandwidth eq "optimal" ) {
				$obw = $ks_class_stat->optimal_bandwidth();
				print "\tOptimal bandwidth is $obw\n";
			}

			my ( $class_min, $class_max ) = $ks_class_stat->extended_range();
			print "\tClass min: $class_min, Class max: $class_max\n";
			for( my $x=$class_min; $x<=$class_max; $x+=($class_max-$class_min)/100 ) {
				if( !defined $bandwidth ) {
					# use default
					$PDF .= $x . "\t" . $ks_class_stat->pdf( $x, $bw ) . "\n";
				} elsif( defined $bandwidth && $bandwidth eq "optimal" ) {
					$PDF .= $x . "\t" . $ks_class_stat->pdf( $x, $obw ) . "\n";
				} else {
					$PDF .= $x . "\t" . $ks_class_stat->pdf( $x, $bandwidth ) . "\n";
				}
			}
			# end generation of PDF using kernal smoothing for this class
		}
	}
  # reset statistical vehicles for the next class's data
  $class_stat->clear;
  $distribution_hash = undef;
  my $ks_class_stat_ref = ref($ks_class_stat);
  undef $ks_class_stat;
  $ks_class_stat = new $ks_class_stat_ref;
	$report .= "\n" if $stats_only;

} #end iterating over all classes
close INTERP_VAL_DUMP_FILE if( defined $interp_val_dump_file );

print "\nGlobal min val: $min, global max val: $max\n";
print "\n\n***********REPORT********\n\n" . $report . "\n";
if( defined $num_bins ) {
  print "\n\n**********PLOT THESE********\n\n" . $histogram . "\n\n\n";
} else {
  print "\n\n**********PLOT THESE********\n\n" . $PDF . "\n\n\n";
}

