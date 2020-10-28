use strict;
use Getopt::Std;

sub help_mess{
	print "\n", "Analysis of Variants Via Assembly", "\n";
	print "\n";
	print "\t", "-T <Int>", "\t", "Task: ", "\n";
	print "\t", "", "\t", "Categorize:\tCategorize to contiguous, simple, or complex", "\n";
	print "\t", "-i <File>", "\t", "Input: Mummer coord file sorted by query", "\n";
    print "\t", "-h [Bool]", "\t", "Help. Show this and exits.", "\n";
}

## ARGS #############
my %options;
my $arguments = 'i:o:T:8h';
getopts($arguments, \%options);
my $_input = $options{'i'};
my $_output = $options{'o'};
my $_tasks = $options{'T'};
my $_debug = $options{'8'};
my $_help = $options{'h'};
%options = ();
if($_help){
	help_mess();
	exit;
}
die "Error: No input file found\nUse avva.pl -h for help.\n" if(!$_input);
if(!$_output){
	open OUT, ">&STDOUT";
}
else{
	open OUT, "+>$_output";
}	
## Globals #############

## Main #############
if($_tasks eq 'Categorize'){
	Categorize();
}
else{
	print STDERR "Error: Unknown Task.\n";
	help_mess();
	exit;
}

## Subroutines 
sub Categorize{
	open COR, $_input or die "Error: Can't open file $_input\n";
	my %category;
	my %blocks;
	my ($currQueryChrom, $currRefChrom, $currQueryStrand);
	my ($currRefStart, $currRefEnd, $currQueryStart, $currQueryEnd);
	my $blocks = 0;
	my $SV;
	my $events;
	my $eventPos;
	my $eventBlocks;
	my $queryBlocks;
	my @coords;
	while(my $line = <COR>){
		chomp $line;
		my @info = split /\t/, $line;
		my ($refStart, $refEnd, $queryStart, $queryEnd, $refStrand, $queryStrand, $refChrom, $queryChrom, $queryLength, $queryMapLength) = ($info[0], $info[1], $info[2], $info[3], $info[11], $info[12], $info[13], $info[14], $info[8], $info[5]);
		if($queryChrom ne $currQueryChrom){
			#Check how many blocks
			if($blocks == 1){
				$category{$currQueryChrom} = ['Contiguous', $SV, $events, $eventPos, $eventBlocks, $queryBlocks];
			}
			else{
				if($SV == 1){
					$category{$currQueryChrom} = ['Simple', $SV, $events, $eventPos, $eventBlocks, $queryBlocks];
				}
				elsif($SV > 1){
					$category{$currQueryChrom} = ['Complex', $SV, $events, $eventPos, $eventBlocks, $queryBlocks];
				}
				else{
					$category{$currQueryChrom} = ['Contiguous', $SV, $events, $eventPos, $eventBlocks, $queryBlocks];
				}
			}
			#New analysis
			$currQueryChrom = $queryChrom;
			$blocks = 1;
			$SV = 0;
			$events = '';
			$eventPos = '';
			$eventBlocks = '';
			$queryBlocks = '';
		}
		else{
			#This would be the second or later block
			#Check if chromosome has changed
			my $currPos = $currQueryStrand == 1 ? $currRefEnd : $currRefStart;
			my $pos = $queryStrand == 1 ? $refStart : $refEnd;
			if($refChrom ne $currRefChrom){
				$SV++;
				$events .= "Tn;";
				$eventPos .= "$currRefChrom:$currPos-$refChrom:$pos;";
				$eventBlocks .= "$currRefChrom:$currRefStart:$currRefEnd:$currQueryStrand-$refChrom:$refStart:$refEnd:$queryStrand;";
				$queryBlocks .= "$currQueryChrom:$currQueryStart:$currQueryEnd:$currQueryStrand-$queryChrom:$queryStart:$queryEnd:$queryStrand;";
			}
			#Check if strand has changed
			elsif($queryStrand ne $currQueryStrand){
				$SV++;
				$events .= "Inv;";
				$eventPos .= "$currRefChrom:$currPos-$refChrom:$pos;";
				$eventBlocks .= "$currRefChrom:$currRefStart:$currRefEnd:$currQueryStrand-$refChrom:$refStart:$refEnd:$queryStrand;";
				$queryBlocks .= "$currQueryChrom:$currQueryStart:$currQueryEnd:$currQueryStrand-$queryChrom:$queryStart:$queryEnd:$queryStrand;";
			}
			#if chromosome and strand has not changed, are there jump backs
			else{
				if($queryStrand == 1){
					if($refStart < $currRefStart){
						$SV++;
						$events .= "Tr;";
						$eventPos .= "$currRefChrom:$currPos-$refChrom:$pos;";
						$eventBlocks .= "$currRefChrom:$currRefStart:$currRefEnd:$currQueryStrand-$refChrom:$refStart:$refEnd:$queryStrand;";
						$queryBlocks .= "$currQueryChrom:$currQueryStart:$currQueryEnd:$currQueryStrand-$queryChrom:$queryStart:$queryEnd:$queryStrand;";
					}
				}
				else{
					if($refEnd > $currRefEnd){
						$SV++;
						$events .= "Tr;";
						$eventPos .= "$currRefChrom:$currPos-$refChrom:$pos;";
						$eventBlocks .= "$currRefChrom:$currRefStart:$currRefEnd:$currQueryStrand-$refChrom:$refStart:$refEnd:$queryStrand;";
						$queryBlocks .= "$currQueryChrom:$currQueryStart:$currQueryEnd:$currQueryStrand-$queryChrom:$queryStart:$queryEnd:$queryStrand;";
					}
				}
			}
			$blocks++;
		}
		$currRefChrom = $refChrom;
		$currQueryStrand = $queryStrand;
		$currRefStart = $refStart;
		$currRefEnd = $refEnd;
		$currQueryStart = $queryStart;
		$currQueryEnd = $queryEnd;
		#$blocks{$queryChrom}{$queryStart} = $line;
		#$blocks{$queryChrom}{$queryEnd} = $line;
	}
	close COR;
	
	foreach my $c(sort keys %category){
		print $c, "\t", join("\t", @{$category{$c}}), "\n";
	}
}

