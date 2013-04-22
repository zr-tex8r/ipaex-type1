use strict;

my ($infile, $outfile, $newpsfam, $enc, $spwd) = @ARGV;

my ($s, $x) = ($spwd / 1000, 0.5);
my $fontdimen = sprintf(<<'EOT', $s, $s/2, $s/3, $x, $s/3);
(FONTDIMEN
   (SLANT R 0.0)
   (SPACE R %.6f)
   (STRETCH R %.6f)
   (SHRINK R %.6f)
   (XHEIGHT R %.6f)
   (QUAD R 1.0)
   (EXTRASPACE R %.6f)
   )
EOT

my %ligtable = (
  'ot1' => <<'EOT',
(LIGTABLE
   (LABEL O 55)
   (LIG O 55 O 173)
   (STOP)
   (LABEL O 173)
   (LIG O 55 O 174)
   (STOP)
   (LABEL O 47)
   (LIG O 47 O 42)
   (STOP)
   (LABEL O 140)
   (LIG O 140 O 134)
   (STOP)
   (LABEL O 41)
   (LIG O 140 O 74)
   (STOP)
   (LABEL O 77)
   (LIG O 140 O 76)
   (STOP)
   )
EOT
  't1' => <<'EOT',
(LIGTABLE
   (LABEL O 55)
   (LIG O 55 O 25)
   (LIG O 177 O 177)
   (STOP)
   (LABEL O 25)
   (LIG O 55 O 26)
   (STOP)
   (LABEL O 47)
   (LIG O 47 O 21)
   (STOP)
   (LABEL O 140)
   (LIG O 140 O 20)
   (STOP)
   (LABEL O 41)
   (LIG O 140 O 275)
   (STOP)
   (LABEL O 77)
   (LIG O 140 O 276)
   (STOP)
   (LABEL O 74)
   (LIG O 74 O 23)
   (STOP)
   (LABEL O 76)
   (LIG O 76 O 24)
   (STOP)
   )
EOT
# Character 022 is missing
#   (LABEL O 54)
#   (LIG O 54 O 22)
#   (STOP)
);

{
  local $_; my $done;
  open(my $hi, '<', $infile) or die;
  open(my $ho, '>', $outfile) or die;
  while (<$hi>) {
    if (m/^\(FONTDIMEN/ .. m/^   \)/) {
      if (!$done) {
        print $ho ($fontdimen, $ligtable{$enc});
        $done = 1;
      }
    } elsif (m/^\(FAMILY/) {
      print $ho ("(FAMILY $newpsfam)\n");
    } elsif (!m/^\(CHECKSUM/) {
      print $ho ($_);
    }
  }
  close($hi);
  close($ho);
}
