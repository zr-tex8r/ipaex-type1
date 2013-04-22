use strict;
use Data::Dump 'dump';
my $aglfn_file = "./aglfn.txt";
my $uni_dir = ".";
my $cdmap_file = "ipaex.code.map";
my $map_file = "ipaex-type1.map";
my $auxbat_file = "__aux.bat";
my $slant = ".25";
my @texencname = qw(ot1 t1 ts1);

require 'rep_ipaex.pl';
our %ipaex;
# (*) ttf2pt1 fails if twp characters in one place correspond to
# the same glyph, so 'hide' some characters in the font.
delete $ipaex{0x0020}; # U+0020 = U+00A0 = aj1
delete $ipaex{0x2011}; # U+2011 = U+2010 = aj14
delete $ipaex{0x2012}; # U+2012 = U+2010 = aj14
delete $ipaex{0x2EB2}; # U+2EB2 = U+2EAB = aj14999
delete $ipaex{0x2ED6}; # U+2ED6 = U+2ECF = aj15262

my %agl;
{
  local ($_);
  open(my $hi, '<', $aglfn_file) or die;
  while (<$hi>) {
    (m/^\#/) and next;
    (m/^(\w+);(\w+);/) or die;
    $agl{hex($1)} = $2;
  }
  close($hi);
}
sub gname {
  return $agl{$_[0]} || sprintf("uni%04X", $_[0]);
}

my (%texenc);
{
  local ($_);
  foreach my $enc (@texencname) {
    my @vec = (0) x 256;
    $texenc{$enc} = \@vec;
    open(my $hi, '<', "$uni_dir/bx-$enc.txt") or die;
    while (<$hi>) {
      (/^\#/) and next;
      (/<PUA>/) and next;
      (/^0x(\w+)\t0x(\w+)\t(.*)/) or die;
      $vec[hex($1)] = hex($2);
    }
    close($hi);
  }
  # See the note (*)
  $texenc{t1}[0x7F] = 0x00AD;
  # these are simply bad
  undef $texenc{ts1}[0x0B];
  undef $texenc{ts1}[0x0C];
}
sub vector {
  my ($enc) = @_;
  if ($enc =~ m/^u([0-9a-f]{2})$/) {
    my $x = hex($1) << 8; return [ $x .. ($x | 0xff) ];
  } elsif (defined $texenc{$enc}) {
    return $texenc{$enc};
  } else { die "Encoding '$enc' unknown"; }
}

my @allenc = (@texencname,
  map { sprintf("u%02x", $_) } (0 .. 255)
);
my (@ipaenc, %ipavec);
{
  foreach my $enc (@allenc) {
    my $ok;
    my @vec = map {
      $ok = 1 if ($ipaex{$_});
      ($ipaex{$_}) ? $_ : undef
    } (@{vector($enc)});
    if ($ok) {
      push(@ipaenc, $enc);
      $ipavec{$enc} = \@vec;
    }
  }
}

if (1) {
  open(my $ho, '>', $cdmap_file) or die;
  print $ho <<'EOT';
# ipaex-tex.map
EOT
  foreach my $enc (@ipaenc) {
    print $ho  ("plane $enc\n");
    my $vec = $ipavec{$enc};
    for my $cc (0 .. 0xff) {
      my $uc = $vec->[$cc] or next;
      printf $ho  ("!%02X U+%04X %s\n", $cc, $uc, gname($uc));
    }
  }
  close($ho);
}

if (1) {
  my %psnam = (
    ipxm => 'IMFCTT1',
    ipxg => 'IGFCTT1',
  );
  open(my $ho, '>', $map_file) or die; binmode($ho);
  foreach my $fam (qw(ipxm ipxg)) {
    my $fn = $psnam{$fam};
    foreach my $enc (@ipaenc) {
      print $ho ("$fam-r-$enc $fn-$enc <$fam-r-$enc.pfb\n");
    }
    foreach my $enc (@ipaenc) {
      print $ho ("$fam-ro-$enc $fn-$enc \"$slant SlantFont\" <$fam-r-$enc.pfb\n");
    }
  }
  close($ho);
}

if (1) {
  open(my $ho, '>', $auxbat_file) or die;
  print $ho ("set SLANT=$slant\n");
  print $ho ("set MAP_FILE=$map_file\n");
  print $ho ("set ALL_ENC=@ipaenc\n");
  close($ho);
}
