use strict;
my ($dst_file, $src_file) = @ARGV;
my @src;
{
  open(my $hi, '<', $src_file) or die;
  while (<$hi>) {
    chomp($_); push(@src, $_);
  }
  close($hi);
}
my %dst;
{
  open(my $hi, '<', $dst_file) or die;
  while (<$hi>) {
    chomp($_); $dst{$_} = 1;
  }
  close($hi);
}
my $n = @src;
print STDERR "'$src_file' has $n lines.\n";
@src = grep { !$dst{$_} } (@src);
my $n = @src;
print STDERR "And $n of them are new.\n";
if ($n == 0) {
  print STDERR "Nothing to be done\n";
} else {
  print STDERR "Appending new lines...\n";
  open(my $ho, '>>', $dst_file) or die; binmode($ho);
  foreach (@src) {
    print $ho ("$_\n");
  }
  close($ho);
  print STDERR "Done.\n";
}
