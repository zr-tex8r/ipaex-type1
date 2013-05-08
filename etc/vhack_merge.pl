use strict;
my $prgname = "vhack_merge";
use Data::Dump 'dump';
my $aglfn_file = "./aglfn.txt";
my ($vert_file, $cmap_file, $ttx_in_file, $fam, $pid, $eid, $plane,
   $ttx_out_file, $map_file, $fdx_file, $fdxa_file) = @ARGV;

my $habase;
{
  ($fdxa_file ne '') or die "Some argument missing";
  $habase = hex($plane);
  ($habase > 0) or die "Bad plane value";
  $habase <<= 8;
}

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
my (%cmap, %vert);
{
  local($_);
  open(my $hi, '<', $cmap_file) or die;
  while (<$hi>) {
    chomp($_); my @a = split(m/\t/, $_);
    ($a[2] ne '') or die;
    $cmap{$a[0]} = $a[2];
  }
  close($hi);
  delete $cmap{0xFF5E};
}
{
  local($_);
  open(my $hi, '<', $vert_file) or die;
  while (<$hi>) {
    chomp($_); my @a = split(m/\t/, $_);
    $vert{$a[0]} = $a[1];
  }
  close($hi);
}
my (@ent);
{
  foreach my $uc (keys %cmap) {
    my $gh = $cmap{$uc} or next;
    my $gv = $vert{$gh} or next;
    push(@ent, [ $uc, $gh, $gv ]);
  }
  @ent = sort { $a->[0] <=> $b->[0] } (@ent);
}
{
  local($_); my ($wdidx);
  open(my $hi, '<', $ttx_in_file) or die;
  open(my $hot, '>', $ttx_out_file) or die;
  open(my $hom, '>', $map_file) or die;
  open(my $hof, '>', $fdx_file) or die; binmode($hof);
  open(my $hoa, '>', $fdxa_file) or die; binmode($hoa);
  while (<$hi>) {
    print $hot ($_);
    if (m/^\s*<tableVersion/) {
      print $hot (<<"EOT");
<cmap_format_4 platformID="$pid" platEncID="$eid" language="0">
EOT
      print $hom (<<"EOT");
# map file
#id $pid $eid
plane u$plane
EOT
      print $hof (<<"EOT");
\\ProvidesFile{$fdx_file}
EOT
      print $hoa (<<"EOT");
\\ProvidesFile{$fdxa_file}
EOT
      foreach my $j (0 .. $#ent) {
        my ($uc, $gh, $gv) = @{$ent[$j]};
        if ($uc == 0x301C) { $wdidx = $j; }
        my $uc1 = $habase + $j;
        printf $hot (qq'<map code="0x%X" name="%s"/>\n', $uc1, $gv);
        printf $hom ("!%02X U+%04X %s.vert\n", $j, $uc1, gname($uc));
        my $s = sprintf("%02x/%d", $uc >> 8, $uc & 0xff);
        my $tex = <<"EOT";
\\CJKvdef{m/n/$s}{\\def\\CJK\@plane{$plane}\\selectfont\\CJKsymbol{$j}}
\\CJKvlet{bx/n/$s}{m/n/$s}
EOT
        print $hof ($tex); print $hoa ($tex);
      }
      print $hot (<<'EOT');
</cmap_format_4>
EOT
    }
  }
  {
        my ($uc, $j) = (0xFF5E, $wdidx);
        my $s = sprintf("%02x/%d", $uc >> 8, $uc & 0xff);
        my $tex = <<"EOT";
\\CJKvdef{m/n/$s}{\\def\\CJK\@plane{$plane}\\selectfont\\CJKsymbol{$j}}
\\CJKvlet{bx/n/$s}{m/n/$s}
EOT
        print $hof ($tex); print $hoa ($tex);
  }
  close($hi);
  close($hot);
  close($hom);
  close($hof);
  close($hoa);
}

print STDERR "$prgname completed\n";
# EOF
