#!perl
#
#
#  Re-use build artefacts from previous runs.
#
#  To override and force a rebuild, append "rebuild" to the entry in the source list.  
#  e.g. to rebuild readline  you might use this (without the leading # on each line):
#
#  ###### termcap + readline vybuildit co nejdrive
#  termcap-1.3.1
#  readline-8.2 rebuild


use strict;
use warnings;
use 5.010;

use Archive::Zip qw /:ERROR_CODES/;


my $sources_file = shift @ARGV or die "Need sources file";
my $suffix       = shift @ARGV || '__';
my $bitness      = $suffix eq '_' ? '32' : '64';
die "bitness argument $bitness is invalid, can only be 64 or 32"
  if not $bitness eq '64' and $bitness eq '32';
my $build_dir    = "_${sources_file}" . ($bitness eq 64 ? "__" : "_");
my $zip_dir = '_out';
my $zip_pfx = "${bitness}bit_";

open my $sources_fh, '<', $sources_file
  or die "Cannot open $sources_file, $!";




my @to_build;
my @packaged;

foreach my $line (<$sources_fh>) {
  chomp $line;
  $line =~ s/\s+$//;
  next if !length $line; 
  next if $line =~ /^#/;
  my ($package, $rebuild) = split /\s+/, $line;
  #  only need those flagged as rebuilds
  if (!$rebuild) {
    push @packaged, $package;
  } 
  push @to_build, $package; #  we refilter lower down as there might not be a zip
}

#say 'To build: ' . join " ", @to_build;
#say 'Packaged: ' . join " ", @packaged;

if (@packaged) {
  my @package_zips = sort glob "$zip_dir/*.zip"; 
  foreach my $pkg (@packaged) {
    #say STDERR "PACKAGE IS $pkg";
    #say STDERR "$zip_dir/$zip_pfx$pkg";
    my @targets = grep {m|^$zip_dir/$zip_pfx$pkg|} @package_zips;
    
    next if !@targets; #  we found a zipped package
    
    @to_build = grep {!m/^$pkg$/} @to_build;
    
    my $target = pop @targets;
    say STDERR "Will extract $target to $build_dir";
    my $zip = Archive::Zip->new();
    my $status = $zip->read($target);
    die "Read of $target failed" if $status != AZ_OK;
    $zip->extractTree( 'c', $build_dir );
  }
}

#  This gets ingested by the build script
say join "\n", @to_build;
