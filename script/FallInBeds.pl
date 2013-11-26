#! /usr/bin/perl -w

############################################################################
##
##  CopyRight (c) 2011 Regents of the University of Michigan
##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
############################################################################

use strict;
use warnings;
use Getopt::Long;
use FindBin qw($Bin);

my %hConf;

#############################################################################
## loadConf() : load configuration file and build hash table for configuration
## CopyRight of this subroutine belongs to Hyun Min Kang
#############################################################################
sub loadConf
{
	my $conf = shift;
	
	%hConf = ();
	open(IN,$conf) || die "Cannot open $conf file for reading";
	while(<IN>)
	{
		next if ( /^#/ );  # if the line starts with #, regard them as comment line
		s/#.*$//;          # trim in-line comment lines starting with #
		my ($key,$val);
		if ( /^([^=]+)=(.+)$/ )
		{
			($key,$val) = ($1,$2);
		}
		else
		{
			die "Cannot parse line $_ at line $. in $conf\n";
		}
		
		$key =~ s/^\s+//;  # remove leading whitespaces
		$key =~ s/\s+$//;  # remove trailing whitespaces
		
		if ( !defined($val) )
		{
			$val = "";     # if value is undefined, set it as empty string
		}
		else
		{
			$val =~ s/^\s+//;
			$val =~ s/\s+$//;
		}
		
		# check if predefined key exist and substitute it if needed
		while ( $val =~ /\$\((\S+)\)/ )
		{
			my $subkey = $1;
			my $subval = &getConf($subkey);
			if ($subval eq "")
			{
				die "Cannot parse configuration value $val at line $. of $conf\n";
			}
			$val =~ s/\$\($subkey\)/$subval/;
		}
		$hConf{$key} = $val;
	}
}

my $conf = "";

my $optResult = GetOptions("conf=s",\$conf);

my $usage = <<END;
----------------------------------------------------------------------------------
FallInBeds.pl : Functional annotation of trait-associated variants
----------------------------------------------------------------------------------
This program tests for enrichment of an input list of trait-associated index
SNPs ([chr:pos] format or rsID, hg19) in experimentally annotated regulatory 
domains (BED files).

Note: the index SNPs should be hg19 version. All maf and LD data are from 1000G
EUR samples! (Release date : May 21, 2011)

Version : 1.1.0

Report Bug(s) : jich[at]umich[dot]edu
----------------------------------------------------------------------------------
Usage : perl FallInBeds.pl --conf [conf.file]
----------------------------------------------------------------------------------
END

unless (($optResult)&&($conf))
{
	die "$usage\n";
}

loadConf($conf);

print "--------------------------------------------------------------------------------------------------------\n";
print "Please check your parameters :\n\n";
while (my ($k,$v) = each %hConf)
{
	print "$k\t$v\n";
}
print "--------------------------------------------------------------------------------------------------------\n\n";

use lib "$Bin/../lib";

use FallInBed;

my $FallInBedInstance = new FallInBed;

# Read all configurations to hash. $self->{"conf"}
$FallInBedInstance->ReadConf(%hConf);

# Verify all parameters in config file
$FallInBedInstance->VerifyConf();

# Verify all bed files
$FallInBedInstance->CheckBedFiles();

# Verify index SNPs
$FallInBedInstance->CheckSNPList();

#Create result directories
$FallInBedInstance->CreateAllDIR();

# Creating make file
print "Please waiting for creating makefile ...!\n";
$FallInBedInstance->CreateMakeFile();

print "--------------------------------------------------------------------------------------------------------\n\n";

print "Finished creating makefile ".$FallInBedInstance->{"conf"}->{"OUT_DIR"}."Makefile\n\n";

print "Try 'make -f ".$FallInBedInstance->{"conf"}->{"OUT_DIR"}."MakeFile -n | less' for a sanity check before running\n";
print "Run 'make -f ".$FallInBedInstance->{"conf"}->{"OUT_DIR"}."MakeFile -j[#parallel jobs]'\n";

print "--------------------------------------------------------------------------------------------------------\n";

exit(0);
