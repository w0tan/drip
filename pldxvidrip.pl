#!/usr/bin/env perl
#
# pldxvidrip dvd ripper and encoder
# Copyright (C) 2010 w0tan
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
use strict;
use warnings;
use Getopt::Long;
use DVD::Read;
use subs ('ripVob');
my(%xvidopt,%audopt,%locopt);
my(@titleinf);
my($pname,$dev,$tpick,$fprefix,$xcopt,$acopt,$pass);
# set some default options
%xvidopt = (
	# Frame options
	'vtag' => 'XVID',
	'b' => '1000k',
	'g' => 300,
	# 'g' => 15,
	'bf' => 3,
	'bufsize' => '4096K',
	'maxrate' => '1500k',
	'b_strategy' => 1,
	'qmin' => 3,
	'qmax' => 5,
	'flags' => '+4mv -trellis -aic',
	'cmp' => 2,
	'subcmp' => 2,
	'mbd' => 2,
	's' => 'unset',
	'croptop' => 'unset',
	'cropbottom' => 'unset',
	'cropleft' => 'unset',
	'cropright' => 'unset',
	# aspect 1.3333, 1.7777, 2.35
	'aspect' => '1.7777',
	'r' => 23.9760,
);
%audopt = (
	'ac' => 2,
	'ar' => 48000,
	'ab' => '160k',
);
%locopt = (
	'vcodec' => 'libxvid',
	'acodec' => 'libmp3lame',
	'2pass' =>  '',
	'h' => '',
	'Ltitle' => '',
	'Ltname' => 'unset',
	'Lnoenc' => '',
	'version' => 0.2,
);
#
GetOptions(
	# xvid options
	'b=s' => \$xvidopt{'b'},
	'g=i' => \$xvidopt{'g'},
	'bf=i' => \$xvidopt{'bf'},
	'b_strategy' => \$xvidopt{'b_strategy'},
	'bufsize=s'=> \$xvidopt{'bufsize'},
	'maxrate=s' => \$xvidopt{'maxrate'},
	'mbd=i' => \$xvidopt{'mbd'},
	'cmp=i' => \$xvidopt{'cmp'},
	'qmin=i' => \$xvidopt{'qmin'},
	'qmax=i' => \$xvidopt{'qmax'},
	'flags=s' => \$xvidopt{'flags'},
	'subcmp=i' => \$xvidopt{'subcmp'},
	'vtag=s' => \$xvidopt{'vtag'},
	's=s' => \$xvidopt{'s'},
    'croptop=i' => \$xvidopt{'croptop'},
    'cropbottom=i' => \$xvidopt{'cropbottom'},
    'cropleft=i' => \$xvidopt{'cropleft'},
    'cropright=i' => \$xvidopt{'cropright'},
	'aspect=s' => \$xvidopt{'aspect'},
	'r=f' => \$xvidopt{'r'},
	# audio options
    'ac=i' => \$audopt{'ac'},
    'ar=s' => \$audopt{'ar'},
    'ab=s' => \$audopt{'ab'},
	# program options
    'vcodec=s' => \$locopt{'vcodec'},
    'acodec=s' => \$locopt{'acodec'},
	'h' => \$locopt{'h'},
	'Ltitle=i' => \$locopt{'Ltitle'},
	'Ltname=s' => \$locopt{'Ltname'},
	'Lnoenc' => \$locopt{'Lnoenc'},
);
#
main: {
	$0 =~ m/\S.*\/(\S.*)$/g;
	$pname = $1;
	print("$pname version: $locopt{'version'}\n");
	&main::setDev or die $@;
	@titleinf = &main::getTinfo();
	unless ($locopt{'Ltname'} eq 'unset') { $titleinf[0] = $locopt{'Ltname'}; } 
	print "using \033[0;32m$titleinf[0]\033[0;00m for title name\n";
	foreach(1 .. $#titleinf) {
		print"$titleinf[$_]\n";
	}
	if ($locopt{'Ltitle'}) {
		$tpick = int($locopt{'Ltitle'});
	} else {
		print "Please enter a title number to rip: "; 
		$tpick = int(<STDIN>) or die $@;
	}
	die $@ if (($tpick > $#titleinf) || ($tpick == 0));
	#
	print"\nNow ripping title # $tpick ...\n\n";
	$fprefix = "$titleinf[0].t$tpick";
	die $@ unless &main::ripVob($tpick);
	#
	if ($locopt{'Lnoenc'}) {
		print("Done ripping the disc. Goodbye.\n");
		exit(1);
	}
	&main::ffCmd;
}
#
sub setOpts {
	($xcopt,$acopt) = ('','');
	foreach (sort keys %xvidopt) {
		next if($xvidopt{$_} eq 'unset');
		$xcopt = "$xcopt"." -$_ $xvidopt{$_}";
	}
	foreach (sort keys %audopt) {
		next if($audopt{$_} eq 'unset');
		$acopt = "$acopt"." -$_ $audopt{$_}";
	}
	return(1);
}
sub ffCmd {
	&main::setOpts;
	print(
		"ffmpeg -i \033[0;32m $fprefix.vob".
		"\033[0;00m -vcodec $locopt{'vcodec'} \033[0;31m$xcopt".
		"\033[0;00m -acodec $locopt{'acodec'} \033[0;32m$acopt".
		"\033[1;32m $fprefix.avi\033[0;00m\n"
	);
	system(
		"ffmpeg -i \"$fprefix.vob\"".
		" -vcodec $locopt{'vcodec'} $xcopt".
		" -acodec $locopt{'acodec'} $acopt".
		" \"$fprefix.avi\""
	);
	return(1);
}
sub ripVob($) {
	my $tn = shift;
	# fix me
	print("using: mplayer dvd://$tn -dumpstream -dumpfile $fprefix.vob\n");
	system("mplayer dvd://$tn -dumpstream -dumpfile \"$fprefix.vob\"")
		unless (-e "$fprefix.vob");
	return(1);
}
sub setDev {
	if(-e '/dev/dvd') {
		$dev = '/dev/dvd';
	} else {
		print("Unable to find /dev/dvd !\n");
		print"enter path to dvd device: ";
		$dev = <STDIN>;
	}
	chomp($dev);
	return(1);
}
sub getTinfo {
	my @tinfo;
	my $dvd = DVD::Read->new($dev) or
		die("\[$pname error\]: Please check dvd drive or media\n");
	my $volid = $dvd->volid;
	push(@tinfo, $volid);
	foreach (1 .. $dvd->titles_count) {
		my $tn = $_;
		my $cc = $dvd->title_chapters_count($_);
		my $title = $dvd->get_title($_);
		my $tl = int($title->length/1000/60);
		next if ($tl eq '0');
		my $cat = "title: # $tn : $cc chapters : $tl minutes";
		my $fps = 10;
		my $cnt = 1;
		while ($fps <= 30) {
			my $eta = ((($tl*60)*$xvidopt{'r'})/$fps)/60;
			$cat = $cat . "\nEta\033[0;3$cnt"."m: $eta min at $fps fps\033[0;00m";
			$fps = $fps + 10;
			$cnt = $cnt + 1;
			if ($cnt >= 3) { $cnt = 1; } 
		}
		push(@tinfo, $cat);
	}
	return(@tinfo);
}
