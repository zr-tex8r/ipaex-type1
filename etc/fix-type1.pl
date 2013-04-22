use strict;

my ($infile, $outfile, $newpsfam, $enc) = @ARGV;

my $copyright = <<'EOT'; chomp($copyright);
Copyright(c) Information-technology Promotion Agency, Japan (IPA), 2003-2012. You must accept "http://ipafont.ipa.go.jp/ipa_font_license_v1.html" to use this product.
EOT

{
  local $_; my ($hi, $ho, $oldpsfam);
  open($hi, '<', $infile) && binmode($hi) or die;
  open($ho, '>', $outfile) && binmode($ho) or die;
  while (<$hi>) {
    if (m/^\%!PS-AdobeFont-1\.0: (\w+)/) {
      $oldpsfam = $1;
      print $ho ("%!PS-AdobeFont-1.0: $newpsfam-$enc\n");
    } elsif (m/^\%\%EndComments/) {
      print $ho ("%Copyright: $copyright\n$_");
    } elsif (m/^\/FullName\b/) {
      s/\Q$oldpsfam\E/$newpsfam-$enc/g;
      print $ho ($_);
    } elsif (m/^\/FamilyName\b/) {
      s/\Q$oldpsfam\E/$newpsfam/g;
      print $ho ($_);
    } elsif (m/^\/FontName\b/) {
      s/\Q$oldpsfam\E/$newpsfam/g;
      print $ho ($_);
    } elsif (m/^\/Notice \(.* def$/) {
      $_ = $copyright; s/\(/\\050/g; s/\)/\\051/g;
      print $ho ("/Notice ($_) readonly def\n");
    } else {
      print $ho ($_);
    }
  }
  close($hi);
  close($ho);
}
