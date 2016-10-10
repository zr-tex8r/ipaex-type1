#!/usr/bin/perl
# generate.pl
use strict;
use Cwd qw( getcwd abs_path );
use File::Basename qw( basename dirname );
use File::Copy qw( copy move );
use Time::Local 'timelocal';
use Data::Dump 'dump';
my $prog_name = "generate";
my $version = "0.2.0";
# settings
our $release_date = "2016/10/01";
our $font_location = "C:/home/yato/storage/ipafonts";
our $texucsmap_location = "C:/home/yato/work/texlabo/texucsmapping";
our $zrotfdump_command = "zrotfdump";
our $input_location = ".";
our $output_location = "..";
our @encoding_filter = ();
our $extension_vertical = 1;
our $extension_nonbmp = 1;
our $extension_snowman = 1;
# internal settings
my @family_info = (
  ipxm => { ps => 'IMFCTT1', ex => 'ipaexm', p => 'ipamp' },
  ipxg => { ps => 'IGFCTT1', ex => 'ipaexg', p => 'ipagp' },
);
my @tex_encoding = qw(ot1 t1 ts1);
my $slant_ratio = ".25";
my $default_space_width = 300;
my $afm_dir = "afm";
my $tfm_dir = "tfm";
my $pfb_dir = "type1";
my $aglfn_file = "aglfn.txt";
my $map_file = "ipaex-type1.map";
my $cdmap_file = "ipaex.code.map";
my $vert_data_file = "ipaex-vert.tsv";
my $temp = "__gen".$$."x";
my $kpsewhich = "kpsewhich";
my $ttf2pt1 = "ttf2pt1";
my $afm2tfm = "afm2tfm";
my $t1disasm = "t1disasm";
my $t1asm = "t1asm";
my $tftopl = "tftopl";
my $pltotf = "pltotf";

#--------------------------------------- main

my (@family, %fam_info);
my ($orig_cwd, @encoding, @generated, @map_line);
my (%extension, %extd_enc, @nonbmp_encoding);

sub main {
  initialize(@ARGV);
  generate_codemap();
  filter_encodings();
  process_main();
  ($extension_vertical) and process_vertical();
  ($extension_nonbmp) and process_nonbmp();
  postprocess();
}

sub initialize {
  if (@_) {
    show_usage(); exit;
  }
  # change work directory
  local $_ = upath(dirname($0));
  (-d $_) or error("directory not found", $_);
  info("working directory is", $_);
  $orig_cwd = getcwd();
  chdir($_);
  if (-f "$prog_name.cfg") {
    info("use config file", "$prog_name.cfg");
    require "$prog_name.cfg";
  }
  # prepare
  while (my ($k, $v) = splice(@family_info, 0, 2)) {
    $fam_info{$k} = $v; push(@family, $k);
  }
  # environment check
  foreach (
    $font_location, $texucsmap_location, $input_location,
    $output_location
  ) { (-d $_) or error("directory not found", $_); }
  my @fn = map { $fam_info{$_}{ex}, $fam_info{$_}{p} } (@family);
  foreach (
    (map { "$font_location/$_.ttf" } (@fn)),
    (map { "$texucsmap_location/bx-$_.txt" } (@tex_encoding)),
    "$input_location/$aglfn_file",
  ) { (-f $_) or error("file not found", $_); }
  $_ = system("$zrotfdump_command --help > $temp-1.out");
  unlink("$temp-1.out");
  (!$_) or error("command not available", $zrotfdump_command);
}

sub show_usage {
    print <<"EOT"; exit;
This is '$prog_name' v$version.
Usage: $prog_name
There are no options available.
EOT
}

sub postprocess {
  my $oloc = $output_location;
  # map file
  write_whole($map_file, join("\n", @map_line, ""));
  push(@generated, $map_file);
  # install files
  info("clean up output locations");
  foreach ($afm_dir, $tfm_dir, $pfb_dir) {
    (-d "$oloc/$_") or mkdir("$oloc/$_");
  }
  unlink(glob("$oloc/$afm_dir/*.afm"));
  unlink(glob("$oloc/$tfm_dir/*.tfm"));
  unlink(glob("$oloc/$pfb_dir/*.pfb"));
  foreach (@generated) {
    my $dest = $oloc;
    if    (m/\.afm$/) { $dest .= "/$afm_dir"; }
    elsif (m/\.tfm$/) { $dest .= "/$tfm_dir"; }
    elsif (m/\.pfb$/) { $dest .= "/$pfb_dir"; }
    info("install file", "$dest/$_");
    move($_, "$dest/$_") or error("cannot move file", $_);
  }
  #
  unlink($cdmap_file, glob("$temp-*.*"));
}

sub filter_encodings {
  (@encoding_filter) or return;
  my %chk = map { $_, 1 } (@encoding_filter);
  @encoding = grep { $chk{$_} } (@encoding);
  @nonbmp_encoding = grep { $chk{$_} } (@nonbmp_encoding);
}

#--------------------------------------- the batch

sub process_main {
  foreach my $fam (@family) {
    process_family($fam);
  }
}

sub process_family {
  my ($fam) = @_; local ($_);
  my $psfam = $fam_info{$fam}{ps};
  info("process family", $fam, $psfam);
  my $fontx = "$font_location/" . $fam_info{$fam}{ex} . ".ttf";
  my $fontp = "$font_location/" . $fam_info{$fam}{p} . ".ttf";
  my $spwd = get_space_width($fontx);
  #
  L1:foreach my $enc (@encoding) {
    my $font = (ucs_encoding($enc)) ? $fontx : $fontp;
    my $rnam = "$fam-r-$enc";
    info("process shape", $rnam);
    run(qq'$ttf2pt1 -L$cdmap_file+$enc $font $rnam');
    ($extd_enc{$enc}) and apply_extension($rnam);
    fix_type1_file("$rnam.t1a", "$temp-1.t1a", $fam, $enc);
    run("$t1asm -b $temp-1.t1a $rnam.pfb");
    $_ = read_whole("$rnam.afm"); my $p = s/^.*\.notdef.*$//gm;
    if ($p == 256) {
      unlink("$rnam.t1a", "$rnam.pfb", "$rnam.afm");
      alert("empty afm", "$rnam.afm"); next L1;
    }
    write_whole("$temp-2.afm", $_);
    run("$afm2tfm $temp-2 -u $temp-2");
    run("$tftopl $temp-2 $temp-2");
    fix_pl_file("$temp-2.pl", "$temp-3.pl", $fam, $enc, $spwd);
    run("$pltotf $temp-3 $rnam");
    # slant
    my $snam = "$fam-ro-$enc";
    run("$afm2tfm $temp-2 -u -s $slant_ratio $temp-2");
    run("$tftopl $temp-2 $temp-2");
    fix_pl_file("$temp-2.pl", "$temp-3.pl", $fam, $enc, $spwd);
    run("$pltotf $temp-3 $snam");
    # done
    push(@generated, "$rnam.afm", "$rnam.tfm", "$rnam.pfb");
    push(@generated, "$snam.tfm");
    unlink("$rnam.t1a");
  }
}


sub get_space_width {
  my ($fontx) = @_; local ($_);
  my $spwd = $default_space_width;
  run("$ttf2pt1 -L$cdmap_file+u00 $fontx $temp-1");
  $_ = read_whole("$temp-1.afm");
  ($_) = (m/^C 160 ; WX (\d+)/m) and $spwd = $_;
  info("space width is", $spwd);
  return $spwd;
}

sub apply_extension {
  my ($nam) = @_; local ($_);
  info("EXTENTION", $nam);
  my %rev = map { glyphname($extension{$_}[0]) => $_ }
      (keys %extension);
  my @afmls = split(m/\n/, read_whole("$nam.afm"));
  foreach (@afmls) {
    my ($gn2) = m/; N (\S+) ;/ or next;
    my $uc1 = $rev{$gn2} or next;
    my $gn1 = glyphname($uc1); s/; N (\S+) ;/; N $gn1 ;/;
    my $bb = $extension{$uc1}[1]; s/; B [\-\d ]+ ;/; B $bb ;/;
  }
  run("$t1asm -b $nam.t1a $temp-0.pfb");
  run("$t1disasm $temp-0.pfb $nam.t1a");
  my @t1als = split(m/\n/, read_whole("$nam.t1a"));
  write_whole("$nam.afm", join("\n", @afmls, ""));
  my $skip = 0; my $gn2;
  foreach (@t1als) {
    if ($skip) {
      if (m|^\t\} ND$|) { $skip = 0; }
      else { $_ = undef; }
    }
    if (($gn2) = m|^dup \d+ /(\S+)|) {
      my $uc1 = $rev{$gn2} or next;
      my $gn1 = glyphname($uc1); s|/\S+|/$gn1|;
    } elsif (($gn2) = m|^/(\S+) \{$|) {
      my $uc1 = $rev{$gn2} or next;
      my $gn1 = glyphname($uc1); s|/\S+|/$gn1|;
      $_ .= "\n" . $extension{$uc1}[2]; chomp($_);
      $skip = 1;
    }
  }
  write_whole("$nam.t1a", join("\n",
      grep { defined $_ } (@t1als), ""));
}

#--------------------------------------- gen-codemap

my (%ipaex_cmap, %ipaex_gname, %agl_map, %tex_cmap);
my (%ipaex_uvector);

sub generate_codemap {
  ($extension_snowman) and use_ext_snowman();
  prepare_for_codemap();
  prepare_uvector();
  make_cdmap_file();
  make_map_file();
}

sub glyphname {
  local ($_) = @_;
  return $agl_map{$_} ||
    sprintf(($_ < 0x10000) ? "uni%04X" : "u%X", $_);
}

sub prepare_for_codemap {
  local ($_);
  # %ipaex_cmap
  info("prepare ipaex cmap");
  run("$zrotfdump_command cmap-12 $font_location/ipaexm.ttf",
    "$temp-1.out");
  foreach (split(m/\n/, read_whole("$temp-1.out"))) {
    my ($uc, $gc, $gn) = (m/^(\d+)\t(\d+)\t(\w*)/) or die;
    $ipaex_cmap{$uc} = $gc; $ipaex_gname{$uc} = $gn;
  }
  # (*) ttf2pt1 fails if twp characters in one place correspond to
  # the same glyph, so 'hide' some characters in the font.
  foreach (
    0x0020, # U+0020 = U+00A0 = aj1
    0x2011, # U+2011 = U+2010 = aj14
    0x2012, # U+2012 = U+2010 = aj14
    0x2EB2, # U+2EB2 = U+2EAB = aj14999
    0x2ED6, # U+2ED6 = U+2ECF = aj15262
  ) { delete $ipaex_cmap{$_}; delete $ipaex_gname{$_}; }
  # %agl_map
  info("prepare glyph name map");
  my $agl = "$input_location/$aglfn_file";
  foreach (split(m/\n/, read_whole($agl))) {
    (m/^\#/) and next;
    my ($uc, $gn) = (m/^(\w+);(\w+);/) or die;
    $agl_map{hex($uc)} = $gn;
  }
  # %tex_cmap
  info("prepare TeX encoding cmap");
  foreach my $enc (@tex_encoding) {
    my @vec = (0) x 256; $tex_cmap{$enc} = \@vec;
    my $file = "$texucsmap_location/bx-$enc.txt";
    foreach (split(m/\n/, read_whole("$file"))) {
      (m/^\#/) and next;
      (m/<PUA>/) and next;
      my ($cc, $uc, $n) = (m/^0x(\w+)\t0x(\w+)\t(.*)/) or die;
      $vec[hex($cc)] = hex($uc);
    }
  }
  # See the note (*)
  $tex_cmap{t1}[0x7F] = 0x00AD;
  # these are simply bad
  undef $tex_cmap{ts1}[0x0B];
  undef $tex_cmap{ts1}[0x0C];
}

sub ucsvector {
  my ($enc) = @_;
  my ($x, $t) = ucs_encoding($enc);
  if ($t) {
    $x = $x << 8; return [ $x .. ($x | 0xff) ];
  } elsif (defined $tex_cmap{$enc}) {
    return $tex_cmap{$enc};
  } else { die "Encoding '$enc' unknown"; }
}

sub prepare_uvector {
  foreach my $enc (
    @tex_encoding,
    map { ucs_enc_name($_) } (0 .. 0xFF)
  ) {
    my $vec = make_uvector($enc) or next;
    push(@encoding, $enc);
    $ipaex_uvector{$enc} = $vec;
  }
  foreach my $enc (
    map { ucs_enc_name($_) } (0x200 .. 0x2FF)
  ) {
    my $vec = make_uvector($enc) or next;
    push(@nonbmp_encoding, $enc);
    $ipaex_uvector{$enc} = $vec;
  }
}

sub make_uvector {
  my ($enc) = @_; local ($_); my $ok;
  my @vec = map {
    if (exists $extension{$_}) {
      $ok = 1; $extd_enc{$enc} = 1; $extension{$_}[0]
    } elsif (exists $ipaex_cmap{$_}) {
      $ok = 1; $_
    } else { undef }
  } (@{ucsvector($enc)});
  ($ok) or return;
  return \@vec;
}

sub make_cdmap_file {
  info("make cdmap file", $cdmap_file);
  my @ls = (<<'EOT');
# ipaex-tex.map
EOT
  foreach my $enc (@encoding, @nonbmp_encoding) {
    push(@ls, "plane $enc\n");
    my $vec = $ipaex_uvector{$enc};
    for my $cc (0 .. 0xff) {
      my $uc = $vec->[$cc] or next;
      $_ = sprintf("!%02X U+%04X %s\n", $cc, $uc & 0xFFFF, glyphname($uc));
      push(@ls, $_);
    }
  }
  write_whole($cdmap_file, join('', @ls));
}

sub make_map_file {
  info("make map file");
  my @ls;
  foreach my $fam (@family) {
    my $fn = $fam_info{$fam}{ps}; my $slant = $slant_ratio;
    foreach my $enc (@encoding, @nonbmp_encoding) {
      push(@ls, "$fam-r-$enc $fn-$enc <$fam-r-$enc.pfb");
    }
    foreach my $enc (@encoding, @nonbmp_encoding) {
      push(@ls, "$fam-ro-$enc $fn-$enc \"$slant SlantFont\" <$fam-r-$enc.pfb");
    }
  }
  push(@map_line, @ls);
}

#--------------------------------------- fix type1

my $copyright = <<'EOT'; chomp($copyright);
Copyright(c) Information-technology Promotion Agency, Japan (IPA), 2003-2012. You must accept "http://ipafont.ipa.go.jp/ipa_font_license_v1.html" to use this product.
EOT
my $creationdate = type1_create_date($release_date, "12:00:00");

sub type1_create_date {
  my ($dt, $tm) = @_;
  ($tm =~ m|^\d\d:\d\d:\d\d$|) or error("bad time format", $tm);
  my ($y, $m, $d) = ($dt =~ m|^(\d\d\d\d)/(\d\d)/(\d\d)$|)
       or error("bad date format", $tm);
  my @f = localtime(timelocal(0, 0, 0, $d, $m - 1, $y - 1900));
  my $dow = qw(Sun Mon Tue Wed Thu Fri Sat)[$f[6]];
  my $mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$m-1];
  return "$dow $mon $d $tm $y";
}

sub fix_type1_file {
  my ($infile, $outfile, $fam, $enc) = @_; 
  info("fix type1", "$fam/$enc");
  my $psfam = $fam_info{$fam}{ps};
  local ($_); my (@ls, $oldpsfam);
  foreach (split(m/\n/, read_whole($infile))) {
    if (m|^\%!PS-AdobeFont-1\.0: (\w+)|) {
      $oldpsfam = $1;
      push(@ls, "%!PS-AdobeFont-1.0: $psfam-$enc");
    } elsif (m|^%%CreationDate: |) {
      push(@ls, "%%CreationDate: $creationdate");
    } elsif (m|^% Args: |) {
      s|\S+/(\S+\.ttf)|$1|;
      push(@ls, $_);
    } elsif (m|^\%\%EndComments\b|) {
      push(@ls, "%Copyright: $copyright", $_);
    } elsif (m|^/FullName\b|) {
      s/\Q$oldpsfam\E/$psfam-$enc/g;
      push(@ls, $_);
    } elsif (m|^/FamilyName\b| || m|^/FontName\b|) {
      s/\Q$oldpsfam\E/$psfam/g;
      push(@ls, $_);
    } elsif (m|^/Notice \(.* def$|) {
      $_ = $copyright; s/\(/\\050/g; s/\)/\\051/g;
      push(@ls, "/Notice ($_) readonly def");
    } else {
      push(@ls, $_);
    }
  }
  write_whole($outfile, join("\n", @ls, ""));
}

#--------------------------------------- fix pl file

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

sub fix_pl_file {
  my ($infile, $outfile, $fam, $enc, $spwd) = @_;
  info("fix type1", "$fam/$enc");
  my $psfam = $fam_info{$fam}{ps};
  my $ucsenc = ucs_encoding($enc);
  ($ucsenc) and $spwd = 0;
  my ($s, $x) = ($spwd / 1000, 0.5);
  #
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
  #
  local ($_); my (@ls, $done);
  foreach (split(m/\n/, read_whole($infile))) {
    if (m/^\(FONTDIMEN/ .. m/^   \)/) {
      if (!$done) {
        push(@ls, $fontdimen, $ligtable{$enc});
        $done = 1;
      }
    } elsif (m/^\(FAMILY/) {
      push(@ls, "(FAMILY $psfam)\n");
    } elsif ($ucsenc && m/^   \(CHARWD/) {
      push(@ls, $_, <<'EOT');
   (CHARHT R 0.88)
   (CHARDP R 0.12)
EOT
    } elsif ($ucsenc && m/^   \(CHARHT/) {
    } elsif ($ucsenc && m/^   \(CHARDP/) {
    } elsif (m/^\(CHECKSUM/) {
    } else {
      push(@ls, $_);
    }
  }
  write_whole($outfile, join("\n", @ls, ""));
}

#--------------------------------------- nonbmp hack

my $sh_pid = 99;
my $sh_eid = 0;

sub process_nonbmp {
  info("process NONBMP");
  (@nonbmp_encoding) or return;
  foreach my $fam (@family) {
    process_family_nonbmp($fam);
  }
}

sub process_family_nonbmp {
  my ($fam) = @_; local ($_);
  my $psfam = $fam_info{$fam}{ps};
  info("process family", $fam, $psfam);
  my $nfont = $fam_info{$fam}{ex};
  my $vfont = "$nfont-v";
  my $pfont = "$font_location/$nfont.ttf";
  my $spwd = get_space_width($pfont);
  (glob("$vfont*.*"))
    and error("existing files must not have that name", "$vfont*.*");
  #
  copy($pfont, "$temp-0.ttf") or error("copy failure");
  unlink(glob("$temp*.ttx"));
  run("ttx -i -t cmap $temp-0.ttf");
  (-f "$temp-0.ttx") or error("ttx failure", "$temp-0.ttx");
  nonbmp_merge("$temp-0.ttx", "$vfont.ttx", $fam);
  run("ttx -m $temp-0.ttf $vfont.ttx");
  (-f "$vfont.ttf") or error("ttx failure", "vfont.ttf");
  #
  L1:foreach my $enc (@nonbmp_encoding) {
    my $rnam = "$fam-r-$enc";
    info("process shape", $rnam);
    run(qq'$ttf2pt1 -L"$cdmap_file+pid=$sh_pid,eid=$sh_eid,$enc" ' .
        "$vfont.ttf $rnam");
    #($extd_enc{$enc}) and apply_extension($rnam);
    fix_type1_file("$rnam.t1a", "$temp-1.t1a", $fam, $enc);
    run("$t1asm -b $temp-1.t1a $rnam.pfb");
    $_ = read_whole("$rnam.afm"); my $p = s/^.*\.notdef.*$//gm;
    info($p, $rnam);
    if ($p == 256) {
      unlink("$rnam.t1a", "$rnam.pfb", "$rnam.afm");
      alert("empty afm", "$rnam.afm"); die;next L1;
    }
    write_whole("$temp-2.afm", $_);
    run("$afm2tfm $temp-2 -u $temp-2");
    run("$tftopl $temp-2 $temp-2");
    fix_pl_file("$temp-2.pl", "$temp-3.pl", $fam, $enc, $spwd);
    run("$pltotf $temp-3 $rnam");
    # slant
    my $snam = "$fam-ro-$enc";
    run("$afm2tfm $temp-2 -u -s $slant_ratio $temp-2");
    run("$tftopl $temp-2 $temp-2");
    fix_pl_file("$temp-2.pl", "$temp-3.pl", $fam, $enc, $spwd);
    run("$pltotf $temp-3 $snam");
    # done
    push(@generated, "$rnam.afm", "$rnam.tfm", "$rnam.pfb");
    push(@generated, "$snam.tfm");
    unlink("$rnam.t1a");
  }
  unlink(glob("$vfont*.*"));
}

sub nonbmp_merge {
  my ($ttx_in_file, $ttx_out_file, $fam) = @_;
  local ($_); my (@lst);
  foreach (split(m/\n/, read_whole($ttx_in_file))) {
    push(@lst, "$_\n");
    if (m/^\s*<tableVersion/) {
      push(@lst, <<"EOT");
<cmap_format_4 platformID="$sh_pid" platEncID="$sh_eid" language="0">
EOT
      foreach my $uc (0x20000 .. 0x2FFFF) {
        my $gn = $ipaex_gname{$uc} or next;
        my $uc1 = $uc & 0xFFFF;
        push(@lst, sprintf(
            qq'<map code="0x%X" name="%s"/>\n', $uc1, $gn));
      }
      push(@lst,  <<'EOT');
</cmap_format_4>
EOT
    }
  }
  write_whole($ttx_out_file, join("", @lst));
}

#--------------------------------------- vertical hack

my $vh_pid = 99;
my $vh_eid = 0;
my $vh_plane = "f0";
my %vert_data;

sub process_vertical {
  info("process VERTICAL");
  prepare_vert_data();
  foreach my $fam (@family) {
    process_vert_family($fam);
  }
}

sub prepare_vert_data {
  local ($_);
  foreach (split(m/\n/, read_whole($vert_data_file))) {
    my @gn = split(m/\t/, $_);
    $vert_data{$gn[0]} = $gn[1];
  }
}

sub process_vert_family {
unlink(glob("$temp-*.*"));
  my ($fam) = @_; local ($_);
  my $psfam = $fam_info{$fam}{ps};
  info("process family", $fam, $psfam);
  my $nfont = $fam_info{$fam}{ex};
  my $vfont = "$nfont-v";
  my $pfont = "$font_location/$nfont.ttf";
  my $enc = "u$vh_plane";
  my $vcdmap_file = "$vfont.code.map";
  my $fdx_file = "c70$fam.fdx";
  my $fdxa_file = "c70${fam}a.fdx";
  (glob("$vfont*.*"))
    and error("existing files must not have that name", "$vfont*.*");
  #
  copy($pfont, "$temp-0.ttf") or error("copy failure");
  unlink(glob("$temp*.ttx"));
  run("ttx -i -t cmap $temp-0.ttf");
  (-f "$temp-0.ttx") or error("ttx failure", "$temp-0.ttx");
  vhack_merge("$temp-0.ttx", "$vfont.ttx", $fam, $vcdmap_file,
      $fdx_file, $fdxa_file);
  run("ttx -m $temp-0.ttf $vfont.ttx");
  (-f "$vfont.ttf") or error("ttx failure", "vfont.ttf");
  #
  my $rnam = "$fam-r-u$vh_plane";
  run(qq'$ttf2pt1 -L"$vcdmap_file+pid=$vh_pid,eid=$vh_eid,$enc" ' .
      "$vfont.ttf $rnam");
  fix_type1_file("$rnam.t1a", "$temp-1.t1a", $fam, $enc);
  run("$t1asm -b $temp-1.t1a $rnam.pfb");
  $_ = read_whole("$rnam.afm"); s/^.*\.notdef.*$//gm;
  write_whole("$temp-2.afm", $_);
  run("$afm2tfm $temp-2 -u $temp-2");
  run("$tftopl $temp-2 $temp-2");
  fix_pl_file("$temp-2.pl", "$temp-3.pl", $fam, $enc, 0);
  run("$pltotf $temp-3 $rnam");
  push(@map_line, "$rnam $psfam-$enc <$rnam.pfb");
  #
  push(@generated, "$rnam.tfm", "$rnam.pfb");
  push(@generated, $fdx_file, $fdxa_file);
  unlink("$rnam.t1a", "$rnam.afm", glob("$vfont*.*"));
}

sub vhack_merge {
  my ($ttx_in_file, $ttx_out_file, $fam, $vcdmap_file,
      $fdx_file, $fdxa_file) = @_;
  my (@ent); local ($_);
  foreach my $uc (sort { $a <=> $b } (keys %ipaex_gname)) {
    ($uc != 0xFF5E) or next;
    my $gh = $ipaex_gname{$uc} or die;
    my $gv = $vert_data{$gh} or next;
    push(@ent, [ $uc, $gh, $gv ]);
  }
  my $habase = (hex($vh_plane) << 8);
  local($_); my ($wdidx, @lst, @lsm, @lsf, @lsa);
  foreach (split(m/\n/, read_whole($ttx_in_file))) {
    push(@lst, "$_\n");
    if (m/^\s*<tableVersion/) {
      push(@lst, <<"EOT");
<cmap_format_4 platformID="$vh_pid" platEncID="$vh_eid" language="0">
EOT
      push(@lsm, <<"EOT");
# map file
#id $vh_pid $vh_eid
plane u$vh_plane
EOT
      push(@lsf, <<"EOT");
\\ProvidesFile{$fdx_file}
EOT
      push(@lsa, <<"EOT");
\\ProvidesFile{$fdxa_file}
EOT
      foreach my $j (0 .. $#ent) {
        my ($uc, $gh, $gv) = @{$ent[$j]};
        if ($uc == 0x301C) { $wdidx = $j; }
        my $uc1 = $habase + $j;
        push(@lst, sprintf(
            qq'<map code="0x%X" name="%s"/>\n', $uc1, $gv));
        push(@lsm, sprintf(
            "!%02X U+%04X %s.vert\n", $j, $uc1, glyphname($uc)));
        my $s = sprintf("%02x/%d", $uc >> 8, $uc & 0xff);
        my $tex = <<"EOT";
\\CJKvdef{m/n/$s}{\\def\\CJK\@plane{$vh_plane}\\selectfont\\CJKsymbol{$j}}
\\CJKvlet{bx/n/$s}{m/n/$s}
EOT
        push(@lsf, $tex); push(@lsa, $tex);
      }
      push(@lst,  <<'EOT');
</cmap_format_4>
EOT
    }
  }
  {
    my ($uc, $j) = (0xFF5E, $wdidx);
    my $s = sprintf("%02x/%d", $uc >> 8, $uc & 0xff);
    my $tex = <<"EOT";
\\CJKvdef{m/n/$s}{\\def\\CJK\@plane{$vh_plane}\\selectfont\\CJKsymbol{$j}}
\\CJKvlet{bx/n/$s}{m/n/$s}
EOT
    push(@lsf, $tex); push(@lsa, $tex);
  }
  write_whole($ttx_out_file, join("", @lst));
  write_whole($vcdmap_file, join("", @lsm));
  write_whole($fdx_file, join("", @lsf));
  write_whole($fdxa_file, join("", @lsa));
}

#--------------------------------------- snowman something

my %ext_set_snowman = (
  0x26C4 => [ 0xFF0B, "0 -120 1000 880", <<'EOT' ],
129 1000 hsbw
292 488 rmoveto
-27 -14 -13 -28 hvcurveto
-27 14 -14 27 vhcurveto
27 14 14 27 hvcurveto
28 -14 13 -27 vhcurveto
closepath
158 hmoveto
-28 -13 -13 -28 hvcurveto
-27 13 -14 28 vhcurveto
27 14 14 27 hvcurveto
28 -14 13 -27 vhcurveto
closepath
27 -134 rmoveto
-21 18 rlineto
-26 -21 -29 -11 -31 0 rrcurveto
-30 0 -28 11 -26 21 rrcurveto
-21 -18 rlineto
33 -24 35 -12 38 0 rrcurveto
38 0 36 12 32 24 rrcurveto
closepath
-106 -139 rmoveto
-27 -14 -14 -27 hvcurveto
-28 14 -13 27 vhcurveto
27 14 13 28 hvcurveto
27 -14 14 -27 vhcurveto
closepath
-126 vmoveto
-27 -14 -14 -27 hvcurveto
-27 14 -14 27 vhcurveto
27 14 14 27 hvcurveto
27 -14 14 -27 vhcurveto
closepath
146 747 rmoveto
-183 -202 rlineto
-143 -9 -108 -79 0 -94 rrcurveto
0 -50 28 -43 55 -34 rrcurveto
-111 -39 -55 -71 0 -105 rrcurveto
-105 89 -75 110 vhcurveto
344 hlineto
112 87 75 105 hvcurveto
0 105 -56 71 -110 39 rrcurveto
55 34 28 43 0 51 rrcurveto
0 32 -12 26 -24 21 rrcurveto
77 140 rlineto
closepath
-373 -60 rmoveto
81 -77 73 -18 126 0 rrcurveto
17 -15 9 -22 0 -27 rrcurveto
0 -47 -20 -34 -39 -21 rrcurveto
-17 -9 -8 -9 0 -9 rrcurveto
0 -10 7 -8 16 -5 rrcurveto
91 -26 55 -72 0 -93 rrcurveto
-88 -76 -68 -99 vhcurveto
-344 hlineto
-100 -75 68 89 hvcurveto
0 83 53 77 73 23 rrcurveto
28 10 15 10 0 10 rrcurveto
0 10 -6 7 -10 5 rrcurveto
-46 23 -22 36 0 48 rrcurveto
0 81 91 69 127 9 rrcurveto
closepath
192 197 rmoveto
155 -141 rlineto
-73 -131 rlineto
-102 0 -83 27 -65 56 rrcurveto
closepath
endchar
EOT
  0x26C7 => [ 0xFF0D, "0 -120 1000 880", <<'EOT' ],
31 1000 hsbw
883 836 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
-30 -230 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
43 -249 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
-859 -82 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
43 167 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
22 208 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
144 126 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
195 72 rmoveto
-24 -12 -12 -24 hvcurveto
-24 12 -12 24 vhcurveto
24 12 12 24 hvcurveto
24 -12 12 -24 vhcurveto
closepath
-406 1 rmoveto
-23 -12 -12 -24 hvcurveto
-24 12 -12 23 vhcurveto
24 13 12 24 hvcurveto
24 -13 12 -24 vhcurveto
closepath
355 -361 rmoveto
27 14 -13 -28 hvcurveto
-27 -14 -14 -27 vhcurveto
-27 -14 14 27 hvcurveto
28 14 13 27 vhcurveto
closepath
158 hmoveto
27 14 -13 -28 hvcurveto
-27 -14 -14 -27 vhcurveto
-28 -13 14 27 hvcurveto
28 13 13 28 vhcurveto
closepath
27 -134 rmoveto
-32 -24 -36 -12 -38 0 rrcurveto
-38 0 -35 12 -33 24 rrcurveto
21 18 rlineto
26 -21 28 -11 30 0 rrcurveto
31 0 29 11 26 21 rrcurveto
closepath
-85 -157 rmoveto
27 14 -14 -27 hvcurveto
-28 -14 -13 -27 vhcurveto
-27 -14 13 28 hvcurveto
27 14 14 27 vhcurveto
closepath
-126 vmoveto
27 14 -14 -27 hvcurveto
-27 -14 -14 -27 vhcurveto
-27 -14 14 27 hvcurveto
27 14 14 27 vhcurveto
closepath
146 747 rmoveto
-183 -202 rlineto
-143 -9 -108 -79 0 -94 rrcurveto
0 -50 28 -43 55 -34 rrcurveto
-111 -39 -55 -71 0 -105 rrcurveto
-105 89 -75 110 vhcurveto
344 hlineto
112 87 75 105 hvcurveto
0 105 -56 71 -110 39 rrcurveto
55 34 28 43 0 51 rrcurveto
0 32 -12 26 -24 21 rrcurveto
77 140 rlineto
closepath
endchar
EOT
);

sub use_ext_snowman {
  while (my ($k, $v) = each %ext_set_snowman) {
    $extension{$k} = $v;
  }
}

#--------------------------------------- helpers

my $windows = ($^O =~ m/^MSWin/);

sub upath {
  local ($_) = @_;
  ($windows) and s|\\|/|g;
  return $_;
}

sub ucs_enc_name {
  local ($_) = @_;
  return sprintf(($_ < 0x100) ? "u%02x" : "u%04x", $_);
}
sub ucs_encoding {
  local ($_) = @_; ($_) = m/^u([0-9a-f]{2,4})$/;
  return (defined $_) ? (hex($_), 1) : (undef, 0);
}

sub kpse_find {
  my ($file, @opt) = @_;
  local $_ = `$kpsewhich @opt $file`; chomp($_);
  ($_ ne '') or error("file not found by kpsewhich", $file);
  return $_;
}

sub run {
  my ($cmd, $out_file, $err_file) = @_; my @temp;
  info("run", $cmd);
  if (!defined $out_file) {
    $out_file = "$temp-r1.out"; push(@temp, $out_file);
  }
  if (!defined $err_file) {
    $err_file = "$temp-r2.out"; push(@temp, $err_file);
  }
  ($out_file ne '-') and $cmd .= " 1>$out_file";
  ($err_file ne '-') and $cmd .= " 2>$err_file";
  local $_ = system($cmd);
  unlink(@temp);
  (!$_) or error("command failed", "code=" . ($_ >> 8), $cmd);
}

sub write_whole {
  my ($path, $data) = @_; local ($_);
  open(my $ho, '>', $path) or error("cannot open to write", $path);
  binmode($ho); print $ho ($data);
  close($ho);
}
sub read_whole {
  my ($path, $data) = @_; local ($_, $/);
  open(my $hi, '<', $path) or error("cannot open to read", $path);
  $_ = <$hi>;
  close($hi);
  return $_;
}

sub info {
  print STDERR (join(": ", $prog_name, @_), "\n");
}
sub alert {
  info("warning", @_);
}
sub error {
  info(@_); exit(-1);
}

#--------------------------------------- go to main
main();
## EOF
