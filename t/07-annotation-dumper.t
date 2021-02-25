use Test;
use lib 'lib';
use lib 't/lib';
use Racoco::PrecompFile;
use Racoco::Annotation;
use Racoco::UtilExtProc;
use Racoco::Constants;
use Racoco::Fixture;

plan 2;

my $proc = RunProc.new;
my $file = 't-resources'.IO.add('root-folder').add('lib').add($DOT-PRECOMP)
  .add('7011F868022706D0DB123C03898593E0AB8D8AF3')
  .add('B8').add('B8FF02892916FF59F7FBD4E617FCCD01F6BCA576');

my $dumper = DumperReal.new(:moar<moar>, :$proc);
is $dumper.get($file), (1, 2), 'annotation dumper ok';

{
  my $err = $*ERR;
  LEAVE { $*ERR = $err; }
  $*ERR = Fixture::devNullHandle;
  is DumperReal.new(:moar<not-exists>, :$proc).get($file), (), 'bad moar';
}

done-testing