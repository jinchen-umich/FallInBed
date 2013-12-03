#! /usr/bin/perl -w

package SNPDictionary;

use strict;
use warnings;
#use FindBin qw($Bin);
use DB_File;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(setVer openSNPDB closeSNPDB rsToChrPos ChrPosTors);

sub new
{
	my $self = {};

	$self->{"rs2chrpos"} = {};
	$self->{"chrpos2rs"} = {};

	$self->{"ver"} = "Not_Set";
	
	bless $self;

	return $self;
}

sub setVer
{
	my $self = shift;

	my ($ver) = @_;

	if ($ver =~ /^hg18$/i)
	{
		$self->{"ver"} = "hg18";
	}
	elsif ($ver =~ /^hg19$/)
	{
		$self->{"ver"} = "hg19";
	}
}

sub openSNPDB
{
	my $self = shift;

	my ($refDIR) = @_;

	if (!(-e $refDIR))
	{
		print "reference file directory doesn't exist!\n";

		exit(1);
	}
	else
	{
		if ($refDIR !~ /\/$/)
		{
			$refDIR = $refDIR."/";
		}
	}

	print "Please wait for connecting with SNP database ......\n";

	my $rs2chrposfile;
	my $chrpos2rsfile;

	undef %{$self->{"rs2chrpos"}};
	undef %{$self->{"chrpos2rs"}};

	if ($self->{"ver"} eq "hg18")
	{
		$rs2chrposfile = $refDIR."rsidToCHRPOS.hg18.dbm";
		$chrpos2rsfile = $refDIR."CHRPOSTorsid.hg18.dbm";
	}
	elsif ($self->{"ver"} eq "hg19")
	{
		$rs2chrposfile = $refDIR."rsidToCHRPOS.hg19.dbm";
		$chrpos2rsfile = $refDIR."CHRPOSTorsid.hg19.dbm";
	}

	if (-e $rs2chrposfile)
	{
		dbmopen (%{$self->{"rs2chrpos"}},$rs2chrposfile,0644) or die "can't open the $rs2chrposfile!\n";
	}
	else
	{
		print "$rs2chrposfile doesn't exist! Please make sure you have downloaded all reference files!\n";

		exit(0);
	}

	if (-e $chrpos2rsfile)
	{
		dbmopen (%{$self->{"chrpos2rs"}},$chrpos2rsfile,0644) or die "can't open the $chrpos2rsfile!\n";
	}
	else
	{
		print "$chrpos2rsfile doesn't exist! Please make sure you have downloaded all reference files!\n";

		exit(0);
	}
}

sub closeSNPDB
{
	my $self = shift;

	print "Please wait for closing the SNP database ......\n";
	
	dbmclose(%{$self->{"rs2chrpos"}});
	dbmclose(%{$self->{"chrpos2rs"}});
}

sub rsToChrPos
{
	my $self = shift;

	my ($rsid) = @_;

	my $snp = "NA";

	if (exists($self->{"rs2chrpos"}->{$rsid}))
	{
		$snp = $self->{"rs2chrpos"}->{$rsid};
	}

	return ($snp);
}

sub ChrPosTors
{
	my $self = shift;

	my ($snp) = @_;

	$snp =~ s/^chr//;
	
	if ($snp =~ /^(\d+|X|x|Y|y):(\d+)$/)
	{
		my $chr = $1;
		my $pos = $2;
		
		if ($chr =~ /^x$/i)
		{
			$chr = 23;
		}
		elsif ($chr =~ /^y$/i)
		{
			$chr = 24;
		}
		
		$snp = $chr.":".$pos;
	}

	my $rsid = "NA";

	if (exists($self->{"chrpos2rs"}->{$snp}))
	{
		$rsid = $self->{"chrpos2rs"}->{$snp};
	}
	
	return ($rsid);
}
	
1;
