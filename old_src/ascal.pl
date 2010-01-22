#!/usr/bin/env perl
use POSIX;
use strict;
use warnings;
my (
  $raw_ar,
  $unsc_w,
  $unsc_h,
  $enced_at,
  $sc_w,
  $sc_h,
  $pic_ar,
  $bps,
  $fps,
  $w,
  $h,
  $diff,
  $new_ar,
  $pic_ar_error,
);

$raw_ar = 720/480;

if (scalar(@ARGV) < 4) {
  &argerr;
  exit(1);
}

($unsc_w, $unsc_h) = split('x', $ARGV[0]);
$enced_at = $ARGV[1];

if ($enced_at =~ /\//) {
  my @a = split(/\//, $enced_at);
  $enced_at = $a[0] / $a[1];
} 
elsif ($enced_at =~ /\d\.\d.*/) {
  $enced_at = $enced_at;
}

$sc_w = $unsc_w * ($enced_at / ($raw_ar));
$sc_h = $unsc_h;
$pic_ar = $sc_w / $sc_h;

($bps, $fps) = @ARGV[2, 3];

printf("Prescaled picture:\033[1;32m %dx%d\033[0m, AR\033[1;33m %.2f\n",
  $sc_w, $sc_h,$pic_ar);

for ($w = 720; $w >= 320; $w -= 16) {

  $h = 16 * round($w / $pic_ar / 16);
  $diff = round($w / $pic_ar - $h);
  $new_ar = $w / $h;
  $pic_ar_error = abs(100 - $pic_ar / $new_ar * 100);

  printf(
    "\033[1;32m${w}x${h}\033[0m, ".
    "diff\033[1;33m % 3d\033[0m, new AR\033[1;32m %.2f\033[0m, ".
    "AR error\033[1;33m %.2f%% \033[0mscale=\033[1;32m%d:%d \033[0mbpp:\033[1;33m %.3f\033[0m\n",
    $diff,$new_ar,$pic_ar_error,$w,$h,
    ($bps * 1000) / ($w * $h * $fps)
  );
}
sub argerr {
  print(
    "Usage: $0 [716x472] [16/9] [800] [23.976]\n".
    "1) the cropped but unscaled resolution\n" .
    "2) the aspect ratio\n" .
    "3) the video bitrate in kbps\n".
    "4) the movie's fps.\n"
  );
}
sub round {
  my $v = shift;
  return floor($v + 0.5);
}
