#!/bin/bash
#
#   Check the system for files needed by FallInBed
#
#   Usgae:   check_requirements.sh  [install_dir]
#
#     eg.    check_requirements.sh /FallInBed
#
#   install_dir defaults to /usr/local/FallInBed
#

DIR=$0
CURRENTPATH=$PWD

if [ "$DIR" = "./check_requirements.sh" ]
then
	DIR=$CURRENTPATH
	DIR=${DIR/%\/script/}
elif [[ "$DIR" =~ check_requirements.sh ]]
then
	DIR=${DIR/%\/check_requirements\.sh/}
	DIR=${DIR/%\/script/}
	DIR=${DIR/#\./}
	DIR=$CURRENTPATH$DIR
fi

banner="#============================================================"

#================================================================
#   Check on Redhat or CentOS systems
#================================================================
if [ ! -d /etc/apt ]; then
    echo $banner
    echo "#   We are not ready for non-Debian systems"
    echo $banner
    exit 1
else
		echo "Good, you are in Debian system"
fi

#================================================================
#   Check on Debian systems
#================================================================
inst='sudo apt-get install'

#   Sanity checks
t=`which perl`
if [ "$t" = "" ]; then
  echo $banner
  echo "#   'perl' is not installed, do go to 'www.perl.org' to download and install perl on your system"
  echo $banner
else
  echo "Good, you appear to have 'perl' installed"
fi

t=`which make`
if [ "$t" = "" ]; then
  echo $banner
  echo "#   'make' is not installed, do '$inst make'"
  echo $banner
else
  echo "Good, you appear to have 'make' installed"
fi

if [ -d $DIR/example ]; then
  echo "Good, you appear to have 'FallInBed-example' installed"
  echo "Test this install:  perl $DIR/script/FallInBed.pl --conf $DIR/example/example.conf"
else
  echo $banner
  echo "#   '$DIR/example' does not exist so you cannot do example demo test in this install"
  echo $banner
fi

exit
