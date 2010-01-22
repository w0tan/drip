#!/usr/bin/env perl
#
# pldh246rip dvd ripper and encoder
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
my(%h264opt,%ffmopt,%audopt,%locopt);
my(@titleinf);
my($pname,$dev,$tpick,$fprefix,$hcopt,$acopt,$pass);
#
%h264opt = (
	# Frame options
	'b' => '1200k',
	# 'g' => 15,
	'bf' => 12,
	'bufsize' => '4096k',
	'maxrate' => '1500k',
	'crf' => 'unset',
	'deinterlace' => '',
	# encoder options
	'g' => 'unset',
	'refs' => 5,
	'b_strategy' => 1,
	'coder' => 1,
	'qmin' => 10,
	'qmax' => 51,
	'sc_threshold' => 40,
	'flags' => '',
	'cmp' => '+chroma',
	'me_range' => 16,
	'me_method' => 'umh',
	'subq' => 9,
	'i_qfactor' => 0.71,
	'qcomp' => 0.6,
	'qdiff' => 4,
	'directpred' => 3,
	'flags2' => '+dct8x8+wpred+bpyramid+mixed_refs',
	'partitions' => '+parti8x8+parti4x4+partp8x8+partp4x4+partb8x8',
	'trellis' => 1,
	# format options
	# aspect: 1.3333, 1.7777, 2.35
	'aspect' => '1.7777',
	's' => 'unset',
    'croptop' => 'unset',
    'cropbottom' => 'unset',
    'cropleft' => 'unset',
    'cropright' => 'unset',
	'r' => 23.976,
);
%audopt = (
	'acodec' => 'libfaac',
	'ar' => 48000,
	'ac' => 2,
	'ab' => '160k',
);
%locopt = (
    'vcodec' => 'libx264',
	'2pass' =>  '',
	'h' => '',
	'Ltitle' => '',
	'Lname' => 'unset',
	'Lnoenc' => '',
	'version' => 0.1,
);
#
GetOptions(
	# local options
    '2pass' => \$locopt{'2pass'},
    'Ltitle=i' => \$locopt{'Ltitle'},
	'vcodec=s' => \$locopt{'vcodec'},
    'Lname=s' => \$locopt{'Lname'},
	'Lnoenc' => \$locopt{'Lnoenc'},
	# h264 options
	'deinterlace' => \$h264opt{'deinterlace'},
	'b=s' => \$h264opt{'b'},
    'r=f' => \$h264opt{'r'},
	'g=i' => \$h264opt{'g'},
	'bf=i' => \$h264opt{'bf'},
	'bufsize=s'=> \$h264opt{'bufsize'},
	'maxrate=s' => \$h264opt{'maxrate'},
	'refs=i' => \$h264opt{'refs'},
	'b_strategy=i' => \$h264opt{'b_strategy'},
	'coder=i' => \$h264opt{'coder'},
	'qmin=i' => \$h264opt{'qmin'},
	'qmax=i' => \$h264opt{'qmax'},
	'sc_threshold=i' => \$h264opt{'sc_threshold'},
	'flags=s' => \$h264opt{'flags'},
	'me_range=i' => \$h264opt{'me_range'},
	'me_method=s' => \$h264opt{'me_method'},
	'subq=i' => \$h264opt{'subq'},
	'i_qfactor=f' => \$h264opt{'i_qfactor'},
	'qcomp=f' => \$h264opt{'qcomp'},
	'qdiff=i' => \$h264opt{'qdiff'},
	'directpred=i' => \$h264opt{'directpred'},
	'flags2=s' => \$h264opt{'flags2'},
	'partitions=s' => \$h264opt{'partitions'},
	'trellis=i' => \$h264opt{'trellis'},
	# format opts
	'croptop=i' => \$h264opt{'croptop'},
    'cropbottom=i' => \$h264opt{'cropbottom'},
    'cropleft=i' => \$h264opt{'cropleft'},
    'cropright=i' => \$h264opt{'cropright'},
	'aspect=s' => \$h264opt{'aspect'},
	's=s' => \$h264opt{'s'},
	#  audio options
	'acodec=s' => \$audopt{'acodec'},
	'ar=i' => \$audopt{'ar'},
	'ac=i' => \$audopt{'ac'},
	'ab=s' => \$audopt{'ab'},
	'r=f' => \$h264opt{'r'},
);
#
main: {
	{
    	$0 =~ m/\S.*\/(\S.*)$/g;
    	$pname = $1;
		$h264opt{'flags'} =(
			"+loop ".
			"$h264opt{'flags'}"
		);
	}
    print("$pname version: $locopt{'version'}\n");
	&main::setDev or die $@;
	@titleinf = &main::getTinfo();
	if ($locopt{'Lname'} ne 'unset') {
		$titleinf[0] = $locopt{'Lname'};
	}
	print "using \033[1;32m$titleinf[0]\033[0;00m for title name\n";
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
	if ($locopt{'Lnoenc'}) {
		print("Done ripping the disc. Goodbye.\n");
		exit(1);
	}
	#
	if ($locopt{'2pass'} eq '1') {
		&main::ffCmd2;
	} else {
		&main::ffCmd;
	}
}
#
sub setOpts {
	# FIXME
	if ($h264opt{'deinterlace'}) {
		$h264opt{'deinterlace'} = '';
	}
	($hcopt,$acopt) = ('','');
	foreach (sort keys %h264opt) {
		next if($h264opt{$_} eq 'unset');
		$hcopt = "$hcopt"." -$_ $h264opt{$_}";
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
		"\033[0;00m -vcodec $locopt{'vcodec'} ".
		"\033[0;31m$hcopt \033[0;32m$acopt".
		" \033[1;32m$fprefix.mp4\033[0;00m\n"
		);
    system(
		"ffmpeg -i $fprefix.vob".
		" -vcodec $locopt{'vcodec'}".
		" $hcopt $acopt".
		" $fprefix.mp4"
		);
	return(1);
}
sub ffCmd2 {
	my %oldopt = %audopt;
	if ($locopt{'2pass'} eq '1') {
		$pass = "-pass $locopt{'2pass'}";
		$audopt{'acodec'} ='unset';
		$audopt{'ac'} = 'unset';
		$audopt{'ab'} = 'unset';
		$audopt{'ar'} = 'unset';
		$audopt{'an'} = '';
	} else {
		$pass ='';
	}
	&main::setOpts;
	print(
		"ffmpeg -i \033[0;32m $fprefix.vob".
		"\033[0;00m $pass -vcodec $locopt{'vcodec'}".
		"\033[0;31m $hcopt\033[0;32m $acopt\033[0;00m ".
		"-y \033[1;32m$fprefix.mp4\033[0;00m\n"
		);
	system(
		"ffmpeg -i $fprefix.vob".
		" $pass -vcodec $locopt{'vcodec'}".
		" $hcopt $acopt".
		" -y $fprefix.mp4"
		);
	if ($locopt{'2pass'} eq '1') {
		$locopt{'2pass'}++;
		$pass = "-pass $locopt{'2pass'}";
		%audopt = %oldopt;
		&main::setOpts;
		print(
			"ffmpeg -i \033[0;32m $fprefix.vob".
			"\033[0;00m $pass -vcodec $locopt{'vcodec'}".
			"\033[0;31m $hcopt \033[0;32m$acopt\033[0;00m".
			" -y \033[1;32m$fprefix.mp4\033[0;00m\n"
			);
		system(
			"ffmpeg -i $fprefix.vob".
			" $pass -vcodec $locopt{'vcodec'}".
			" $hcopt $acopt".
			" -y $fprefix.mp4"
			);
	}
	if(-e 'ffmpeg2pass-0.log'){
		unlink ('ffmpeg2pass-0.log');
	}
	if (-e 'x264_2pass.log') {
		unlink('x264_2pass.log');
	}
	return(1);
}
sub ripVob($) {
	my $tn = shift;
	# fix me
	print("using: mplayer dvd://$tn -dumpstream -dumpfile \"$fprefix.vob\"\n");
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
			my $eta = ((($tl*60)*$h264opt{'r'})/$fps)/60;
			$cat = $cat . "\nEta\033[0;3$cnt"."m: $eta min at $fps fps\033[0;00m";
			$fps = $fps + 10;
			$cnt = $cnt + 1;
			if ($cnt >= 3) { $cnt = 1; } 
		}
		push(@tinfo, $cat);
	}
	return(@tinfo);
}
