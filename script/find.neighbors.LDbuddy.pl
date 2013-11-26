#! /usr/bin/perl -w

use strict;
use warnings;
use FindBin qw($Bin);
use DB_File;
use Switch;
use Getopt::Long;
use Time::HiRes qw[gettimeofday tv_interval];
use Fcntl qw(:flock);

my $start = time;
my $startTime = [gettimeofday()];

my $neighborlist;
my $r2Threshold;
my $ldWindowSize;
my $chrid;
my $neighborLDlist;
my $logFile;
my $help;
		  
Getopt::Long::GetOptions(
      'neighborlist=s' => \$neighborlist,
      'r2Threshold=f' => \$r2Threshold,
      'ldWindowSize=i' => \$ldWindowSize,
      'chrid=i' => \$chrid,
      'neighborLDlist=s' => \$neighborLDlist,
			'logFile=s' => \$logFile,
			'help' => \$help);

if (defined($help))
{
	print "perl find.neighbors.LDbuddy.pl --neighborlist neighborlist --r2Threshold r2Threshold --ldWindowSize ldWindowSize --chrid chrid --neighborLDlist neighborLDlist --logFile logFile\n";
	print "perl find.neighbors.LDbuddy.pl --help\n";
				  
	exit(0);
}

if (!defined($neighborlist))
{
	print "No define neighborlist!\n";

	exit(1);
}
elsif (!(-e $neighborlist))
{
	print "$neighborlist doesn't exist!\n";

	exit(1);
}

if (!defined($r2Threshold))
{
	print "No define r2Threshold!\n";

	exit(1);
}

if (!defined($ldWindowSize))
{
	print "No define ldWindowSize!\n";

	exit(1);
}

if (!defined($chrid))
{
	print "No define chrid!\n";

	exit(1);
}

if (!defined($neighborLDlist))
{
	print "No define neighborLDlist!\n";

	exit(1);
}

if (!defined($logFile))
{
	print "No define logFile!\n";

	exit(1);
}

my $logFileLock = $logFile.".lck";

my %neighborHash;

open (IN,$neighborlist) || die "can't the file $neighborlist!\n";
open (OUT,">".$neighborLDlist) || die "can't the file $neighborLDlist!\n";

my %hash;

my $dbm = "$Bin/../ref/chr$chrid.dbm";

if (-e $dbm)
{
	dbmopen (%hash,$dbm,0644) || die "can't open DBM $dbm!\n";
}

print OUT "neighbor_SNP\tLD_buddy_pos\n";

my $readline = <IN>;

while (defined($readline=<IN>))
{
	chomp $readline;

	my @fields = split(/\t/,$readline);
	my @neighbors = split(/\|/,$fields[5]);

	for (my $i = 0; $i < int(@neighbors); $i++)
	{
		my $thisNeighbor = $neighbors[$i];

		if ($thisNeighbor =~ /^($chrid):(\d+)/)
		{
			my $chr = $chrid;
			my $pos = $2;

			if (!exists($neighborHash{$thisNeighbor}))
			{
				my @LDArr;
				undef @LDArr;

				if (exists($hash{$pos}))
				{
					@fields = split(/\t/,$hash{$pos});
					@fields = split(/\|/,$fields[6]);
		      
					for (my $i = 0; $i < int(@fields); $i++)
		      {
						my @tmp = split(/\+/,$fields[$i]);
						my $ldpos = $tmp[0];
						my $r2 = $tmp[1];
						
						my $lddist = abs($pos - $ldpos);
						
						if (($r2 > $r2Threshold)&&($lddist <= $ldWindowSize))
						{
							my $k = int(@LDArr);
							$LDArr[$k] = $ldpos;
						}
					}
				}

				my $numofld = int(@LDArr);

				if ($numofld > 0)
				{
					print OUT "$thisNeighbor\t$LDArr[0]";

					for (my $j = 1; $j < int(@LDArr); $j++)
					{
						print OUT "|$LDArr[$j]";
					}

					print OUT "\n";
				}

				$neighborHash{$thisNeighbor} = 1;
			}
		}
	}
}

close IN;
close OUT;

if (-e $dbm)
{
	dbmclose(%hash);
}

my $end = time;

my $runningTime = tv_interval($startTime) * 1000;

open(SEM,">$logFileLock") or die "Can't create semaphore: $!";

flock(SEM,LOCK_EX) or die "Lock failed: $!";

open (OUT,">>".$logFile) || die "can't write to the file:$!\n";

print OUT "perl find.neighbors.LDbuddy.pl --neighborlist $neighborlist --r2Threshold $r2Threshold --ldWindowSize $ldWindowSize --chrid $chrid --neighborLDlist $neighborLDlist --logFile $logFile start=$start end=$end runningTime=$runningTime\n";

close OUT;

close(SEM);

exit(0);
