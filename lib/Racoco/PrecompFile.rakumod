unit module Racoco::PrecompFile;
use Racoco::X;
use Racoco::Sha;
use Racoco::UtilExtProc;
use Racoco::Constants;

sub get-our-precomp($lib) {
  $lib.parent.add($DOT-RACOCO).add($OUR-PRECOMP);
}

sub get-file-precomp(:$path, :$sha) {
  my $path-wo-ext = $path.extension('').Str;
  my $sha-value = $sha.uc($path-wo-ext);
  my $two-letters = $sha-value.substr(0, 2);
  $two-letters.IO.add($sha-value)
}

class Finder is export {
  has $!sha;
  has @!find-locations;

  method BUILD(:$lib is copy) {
    Racoco::X::WrongLibPath.new(:path($lib)).throw unless $lib.e;
    $lib = $lib.absolute.IO;
    @!find-locations.push: $_ with self!get-raku-location($lib);
    @!find-locations.push: $_ with self!get-our-location($lib);
    $!sha = Racoco::Sha::create()
  }

  method !get-raku-location($lib) {
    my $lib-precomp = $lib.add($DOT-PRECOMP);
    return self!add-compiler-id($lib-precomp) if $lib-precomp.e;
    Nil
  }

  method !get-our-location($lib) {
    my $our-precomp = get-our-precomp($lib);
    return $our-precomp if $our-precomp.e;
    Nil
  }

  method !add-compiler-id($path) {
    my @compiler-ids := $path.dir().grep(*.d).eager.List;
    Racoco::X::AmbiguousPrecompContent.new(:$path).throw
        if @compiler-ids.elems > 1;
    @compiler-ids.elems == 1 ?? $path.add(@compiler-ids[0].basename) !! IO::Path
  }

  multi method find(IO() $path --> IO::Path) {
    for @!find-locations -> $location {
      my $found = $location.add(get-file-precomp(:$path, :$!sha));
      return $found if $found.e;
    }
    return Nil
  }
}

class Maker is export {
  has ExtProc $.proc;
  has IO::Path $.precomp-path;
  has Str $.raku = 'raku';
  has Str $!lib-name;
  has $!sha;

  submethod BUILD(:$lib is copy, :$!raku, :$!proc) {
    $lib = $lib.absolute.IO;
    $!lib-name = $lib.basename;
    $!precomp-path = get-our-precomp($lib);
    $!precomp-path.mkdir;
    $!sha = Racoco::Sha::create()
  }

  method compile(IO() $path --> IO::Path) {
    my $output = $!precomp-path.add(get-file-precomp(:$path, :$!sha));
    $output.parent.mkdir;
    my $proc = $!proc.run(
      $!raku,
      "-I$!lib-name",
      '--target=mbc',
      "--output=$output",
      $path.Str
    );
    $proc.exitcode == 0 ?? $output !! Nil;
  }
}

class Provider is export {
  has $!finder;
  has $!maker;

  method BUILD(:$lib, :$raku, :$proc) {
    $!finder = Finder.new(:$lib);
    $!maker = Maker.new(:$lib, :$raku, :$proc)
  }

  method get($path) {
    $!finder.find($path) // $!maker.compile($path)
  }
}

class HashcodeGetter is export {
  method hashcode(IO() $path --> Str) {
    my $h = $path.open :r;
    LEAVE { .close with $h }
    $h.get
  }
}