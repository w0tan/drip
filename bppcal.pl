#!/usr/bin/env perl
use POSIX;
use strict;
use warnings;
my (
  $raw_aspect,
  $unscaled_width,
  $unscaled_height,
  $encoded_at,
  $scaled_width,
  $scaled_height,
  $picture_ar,
  $bps,
  $fps,
  $width,
  $height,
  $diff,
  $new_ar,
  $picture_ar_error,
);

$raw_aspect = 720/480;

if (scalar(@ARGV) < 4) {
  &argerr;
  exit(1);
}

($unscaled_width, $unscaled_height) = split('x', $ARGV[0]);
$encoded_at = $ARGV[1];

if ($encoded_at =~ /\//) {
  my @a = split(/\//, $encoded_at);
  $encoded_at = $a[0] / $a[1];
} 
elsif ($encoded_at =~ /\d\.\d.*/) {
  $encoded_at = $encoded_at;
}

$scaled_width = $unscaled_width * ($encoded_at / ($raw_aspect));
$scaled_height = $unscaled_height;
$picture_ar = $scaled_width / $scaled_height;

($bps, $fps) = @ARGV[2, 3];

printf("Prescaled picture:\033[1;32m %dx%d\033[0m, AR\033[1;33m %.2f\n",
  $scaled_width, $scaled_height,$picture_ar);

for ($width = 720; $width >= 320; $width -= 16) {

  $height = 16 * round($width / $picture_ar / 16);
  $diff = round($width / $picture_ar - $height);
  $new_ar = $width / $height;
  $picture_ar_error = abs(100 - $picture_ar / $new_ar * 100);

  printf(
    "\033[1;32m${width}x${height}\033[0m, ".
    "diff\033[1;33m % 3d\033[0m, new AR\033[1;32m %.2f\033[0m, ".
    "AR error\033[1;33m %.2f%% \033[0mscale=\033[1;32m%d:%d \033[0mbpp:\033[1;33m %.3f\033[0m\n",
    $diff,$new_ar,$picture_ar_error,$width,$height,
    ($bps * 1000) / ($width * $height * $fps)
  );
}
sub argerr {
  print(
    "Please provide all of the following\n".
    "a) the cropped but unscaled resolution (e.g. 716x472)\n" .
    "b) the aspect ratio (either 4/3 or 16/9 for most DVDs)\n" .
    "c) the video bitrate in kbps (e.g. 800)\n".
    "d) the movie's fps.\n"
  );
}
sub round {
  my $v = shift;
  return floor($v + 0.5);
}
