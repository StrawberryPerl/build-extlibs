use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);
my $date = sprintf("%04d%02d%02d",($yr19+1900),($month+1),$day);

my $desc = {
  'Win32_SDL-1.2.14-extended' => {
    'files' => [
      ['..\..\w32gcc4\bin\libgcc_s_sjlj-1.dll', 'bin\libgcc_s_sjlj-1.dll'],
      ['..\..\build\sdl-readme.txt', "SDL-readme-32bit-$date.txt"],
      ['lib\libSDLmain.a', 'lib\libSDLmain.a'],
      ['lib\libSDL_vnc.a', 'lib\libSDL_vnc.dll.a'], # ugly fix
      ['lib\libSDL_rtf.a', 'lib\libSDL_rtf.dll.a'], # ugly fix
      ['lib\glib-2.0\include\glibconfig.h', 'include\glib-2.0\glibconfig.h'], # ugly fix
    ],
    'trees' => [
#      ['bin', 'bin', 'config$'],
      ['bin', 'bin', '\.bat$'],
      ['bin', 'bin', '\.dll$'],
      ['lib', 'bin', '\.dll$'],
      ['lib', 'lib', '\.dll\.a$'],
      ['etc', 'etc', '.*'],
      ['include', 'include', '\.h$'],
      ['include', 'include', '\.hxx$'],
    ],
  }, 
  'Win64_SDL-1.2.14-extended' => {
    'files' => [
      ['..\..\w64gcc4\bin\libgcc_s_sjlj-1.dll', 'bin\libgcc_s_sjlj-1.dll'],
      ['..\..\build\sdl-readme.txt', "SDL-readme-64bit-$date.txt"],
      ['lib\libSDLmain.a', 'lib\libSDLmain.a'],
      ['lib\libSDL_vnc.a', 'lib\libSDL_vnc.dll.a'], # ugly fix
      ['lib\libSDL_rtf.a', 'lib\libSDL_rtf.dll.a'], # ugly fix
    ],
    'trees' => [
 #     ['bin', 'bin', 'config$'],
      ['bin', 'bin', '\.bat$'],
      ['bin', 'bin', '\.dll$'],
      ['lib', 'bin', '\.dll$'],
      ['lib', 'lib', '\.dll\.a$'],
      ['etc', 'etc', '.*'],
      ['include', 'include', '\.h$'],
      ['include', 'include', '\.hxx$'],
    ],
  }, 
};  

sub prepare_pack {
  my ($jobname, $datestamp, $deschash, $binroot, $srcroot, $pkgprefix) = @_;
  my $zipname = "$pkgprefix$jobname\-bin_$datestamp.zip"; 
  
  print STDERR "GONNA CREATE: '$zipname'\n";
  print STDERR "  using source dir: '$srcroot'\n" if $srcroot;
  print STDERR "  using binary dir: '$binroot'\n" if $binroot;
  
  # Create a Zip file
  my $zip = Archive::Zip->new();

  # Process 'files'
  foreach my $i (@{$deschash->{$jobname}->{'files'}}) {
    my $src = $i->[0];
    $src = $binroot . '/' . $src if $binroot;
    my $dst = $i->[1];
    $src =~ s/\\/\//g;
    $dst =~ s/\\/\//g;
	if (-e $src) {
      my $f = $zip->addFile($src, $dst);
      if($f) {    
        print STDERR "  added(file): '$src'#'$i->[1]'\n";
        $f->desiredCompressionLevel(9);
      }
      else {
        print STDERR "  ###error###: cannot add(file) '$src'#'$i->[1]'!\n";
      }
	}
	else {
      print STDERR "  ###error###: non existing file'$src'\n";
	}
  };
  
  # Process 'trees'
  foreach my $i (@{$deschash->{$jobname}->{'trees'}}) {
    my $src = $i->[0];
    $src = $binroot . '/' . $src if $binroot;
    my $dst = $i->[1];
    $src =~ s/\\/\//g;
    $dst =~ s/\\/\//g;
    my $f = $zip->addTreeMatching($src, $dst, $i->[2]);
    if($f == AZ_OK) {    
      print STDERR "  added(tree): '$src'#'$i->[1]'#'$i->[2]'\n";
    }
    else {
      print STDERR "  ###error###: cannot add(tree) '$src'#'$i->[1]'#'$i->[2]'\n";
    }
  };

  # Process 'licenses'
  foreach my $src (@{$deschash->{$jobname}->{'licenses'}}) {
    $src = $srcroot . '/' . $src if $srcroot;
    my $file = $src;
    $file =~ s/^.*?([^\/\\]*)$/$1/;
    my $dst = $deschash->{$jobname}->{'licdir'} . '/' . $file;
    $src =~ s/\\/\//g;
    $dst =~ s/\\/\//g;
    my $f = $zip->addFile($src, $dst);
    if($f) {    
      print STDERR "  added(license): '$src'\n";
      $f->desiredCompressionLevel(9);
    }
    else {
      print STDERR "  ###error###: cannot add(license) '$src'!\n";
    }
  };

  # Process 'urls'
  my $urlinfo="Package: $jobname\n";
  foreach my $i (@{$deschash->{$jobname}->{'urls'}}) {
    $urlinfo .= "$i->[0]: $i->[1]\n";
  };

  # Save the Zip file
  die 'ZIP write error' unless ( $zip->writeToFileNamed($zipname) == AZ_OK );
  print STDERR "FINISHED: '$zipname'\n";
}

prepare_pack ( 'Win32_SDL-1.2.14-extended', $date, $desc,
               '_wrk_sdl-specbuild_sdl32.patched/', '_wrk_sdl-specbuild_sdl32/', '' ) if -d '_wrk_sdl-specbuild_sdl32.patched';
prepare_pack ( 'Win64_SDL-1.2.14-extended', $date, $desc,
               '_wrk_sdl-specbuild_sdl64.patched/', '_wrk_sdl-specbuild_sdl64/', '' ) if -d '_wrk_sdl-specbuild_sdl64.patched';
