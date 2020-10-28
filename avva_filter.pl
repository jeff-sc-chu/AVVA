use strict;
use Getopt::Std;

sub help_mess{
	print "\n", "Filter SV events from AVVA", "\n";
	print "\n";
	print "\t", "-T <Int>", "\t", "Task: ", "\n";
	print "\t", "", "\t", "FilterRefContig:\tFilter restuls of Categorize with a reference event set", "\n";
	print "\t", "", "\t", "FilterGap:\tFilter events bordering gaps", "\n";
	print "\t", "", "\t", "FilterVCF:\tFilter with a Illumina/PacBio Call set", "\n";
	print "\t", "-i <File>", "\t", "Output file from avva.pl to be filtered", "\n";
	print "\t", "-j <File>", "\t", "Output file from avva.pl to be used a reference", "\n";
	print "\t", "-g <File>", "\t", "GapInfo file", "\n";
	print "\t", "-k [Bool]", "\t", "Keep filtered results (1) or remove filtered results (default, or 0).", "\n";
    print "\t", "-h [Bool]", "\t", "Help. Show this and exits.", "\n";
}

## ARGS #############
my %options;
my $arguments = 'i:o:T:r:j:e:g:c:k8hp';
getopts($arguments, \%options);
my $_input = $options{'i'};
my $_output = $options{'o'};
my $_tasks = $options{'T'};
my $_debug = $options{'8'};
my $_help = $options{'h'};
my $_refFile = $options{'j'};
my $_gapInfoFile = $options{'g'};
my $_keepFilter = $options{'k'};
%options = ();
if($_help){
	help_mess();
	exit;
}
if(!$_output){
	open OUT, ">&STDOUT";
}
else{
	open OUT, "+>$_output";
}
die "Error: Required input (-i) missing.\n" if(!$_input);	
## Globals #############
my %gap;
my %ref;
## Main #############
if($_tasks eq 'FilterRefContig'){
	die "Error: Required ref set (-j) missing.\n" if(!$_refFile);
	FilterRefContig();
}
elsif($_tasks eq 'FilterGap'){
	if(!$_gapInfoFile){
		help_mess();
		print STDERR "Error: Required GapInfo file (-g) missing.\n";
		exit;
	}
	populateGap();
	FilterGap();
}
elsif($_tasks eq 'FilterVCF'){
	die "Error: Required VCF input (-j) missing.\n" if(!$_refFile);
	populateVCF();
	FilterVCF();
}
else{
	help_mess();
	print STDERR "Error: Unknown Task.\n";
	exit;
}

## Subroutines 
sub FilterVCF{
	open IN, $_input;
	while(my $line = <IN>){
		chomp $line;
		my @info = split /\t/, $line;
		my ($category, $eventPosLine) = ($info[1], $info[4]);
		#my ($contig, $category, $eventCount, $events, $eventPosLine) = split /\t/, $line;
		next if($category eq 'Contiguous');
		my $support = '';
		my @eventPos = split /;/, $eventPosLine;
		foreach my $eventPos(@eventPos){
			my $supportStatus = 0;
			my ($chr1, $pos1, $chr2, $pos2) = $eventPos =~ /(\S+):(\d+)-(\S+):(\d+)/;
			for(my $i = $pos1-1000; $i <= $pos1+1000; $i++){
				if($ref{$chr1}{$i}){
					$support .= 'S';
					$supportStatus = 1;
					last;
				}
			}			
			if(!$supportStatus){
				for(my $i = $pos2-1000; $i <= $pos2+1000; $i++){
					if($ref{$chr2}{$i}){
						$support .= 'S';
						$supportStatus = 1;
						last;
					}
				}	
			}
			if(!$supportStatus){
				$support .= 'x';
			}
=cut
			if($ref{$chr1}{$pos1} || $ref{$chr2}{$pos2}){
				$support .= 'S';
			}
			else{
				$support .= 'x';
			}
=cut
		}

		if($_keepFilter){
			print $line, "\t", $support, "\n";
		}
		else{
			print $line, "\t", $support, "\n" if $support =~ /x/;
		}
		
	}
	close IN;	
}

sub FilterGap{
	open IN, $_input;
	while(my $line = <IN>){
		chomp $line;
		my ($contig, $category, $eventCount, $events, $eventPosLine) = split /\t/, $line;
		next if($category eq 'Contiguous');
		my $borderGap = '';
		my @eventPos = split /;/, $eventPosLine;
		foreach my $eventPos(@eventPos){
			my ($chr1, $pos1, $chr2, $pos2) = $eventPos =~ /(\S+):(\d+)-(\S+):(\d+)/;
			if($gap{$chr1}{$pos1} || $gap{$chr2}{$pos2}){
				$borderGap .= 'G';
			}
			else{
				$borderGap .= 'n';
			}	
		}
		print $line, "\t$borderGap\n" if $borderGap =~ /n/;
	}
	close IN;	
}

sub FilterRefContig{
	my %ref;
	open REF, $_refFile;
	while(my $line = <REF>){
		chomp $line;
		my ($contig, $category, $eventCount, $events, $eventPosLine) = split /\t/, $line;
		next if($category eq 'Contiguous');
		my @eventPos = split /;/, $eventPosLine;
		foreach my $eventPos(@eventPos){
			my ($chr1, $pos1, $chr2, $pos2) = $eventPos =~ /(\S+):(\d+)-(\S+):(\d+)/;
			for(my $i = $pos1 - 1000; $i < $pos1 + 1000; $i++){
				$ref{$chr1}{$i} = 1;
			}
			for(my $i = $pos2 - 1000; $i < $pos2 + 1000; $i++){
				$ref{$chr2}{$i} = 1;
			}
		}
	}
	close REF;
	open IN, $_input;
	while(my $line = <IN>){
		chomp $line;
		my $control;
		my ($contig, $category, $eventCount, $events, $eventPosLine) = split /\t/, $line;
		next if($category eq 'Contiguous');
		my @eventPos = split /;/, $eventPosLine;
		foreach my $eventPos(@eventPos){
			my ($chr1, $pos1, $chr2, $pos2) = $eventPos =~ /(\S+):(\d+)-(\S+):(\d+)/;
			if($ref{$chr1}{$pos1} || $ref{$chr2}{$pos2}){
				$control .= 'C';
			}
			else{
				$control .= 'n';
			}
		}
		print $line, "\t", $control, "\n" if $control =~ /n/;
	}
	close IN;
}

sub populateGap{
	open GAP, $_gapInfoFile;
	while(my $line = <GAP>){
		chomp $line;
		my ($chrom, $gapS, $gapE) = $line =~ /^(\S+):(\d+)-(\d+)/;
		for(my $i = $gapS - 50; $i <= $gapS; $i++){
			$gap{$chrom}{$i} = 1;
		}
		for(my $i = $gapE; $i <= $gapE + 50; $i++){
			$gap{$chrom}{$i} = 1;
		}
	}
	close GAP;
}

sub populateVCF{
	open REF, $_refFile;
	while(my $line = <REF>){
		chomp $line;
		next if($line =~ /^#/);
		my @info = split /\t/, $line;
		my ($svType) = $line =~ /SVTYPE=(.*?);/;
		my ($end) = $line =~ /END=(\d+)/;
		$end = 0 if !$end;
		my $endChr = $info[0];
		if($svType eq "BND"){
			($endChr, $end) = $info[4] =~ /(Chrom\d+):(\d+)/;
		}
		$ref{$info[0]}{$info[1]} = 1;
		if($end){
			$ref{$endChr}{$end} = 1;
		}
	}

	close REF;
}
