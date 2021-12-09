use Test;
use lib 'lib';
use lib 't/lib';
use App::Racoco::Coverable::CoverableOutliner;
use App::Racoco::RunProc;
use App::Racoco::Paths;
use App::Racoco::Fixture;
use TestResources;

plan 2;

my ($lib, $path, $outliner, $subtest);
sub setup($lib-name, $proc, :$subtest, :$plan!) {
	plan $plan;
	TestResources::prepare($subtest);
	$lib = TestResources::exam-directory.add($lib-name);
	$path = lib-precomp-path(:$lib).add(Fixture::compiler-id())
    .add('B8').add('B8FF02892916FF59F7FBD4E617FCCD01F6BCA576');
	$outliner = CoverableOutlinerReal.new(:moar<moar>, :$proc);
}

$subtest = '01-real-outline';
subtest $subtest, {
	setup('lib', RunProc.new, :$subtest, :1plan);
	is $outliner.outline(:$path), (1, 2), 'coverable outline ok';
}

$subtest = '02-fail-outline';
subtest $subtest, {
	setup('lib', Fixture::failProc, :$subtest, :1plan);
	Fixture::suppressErr;
  LEAVE { Fixture::restoreErr }
  is $outliner.outline(:$path), (), 'fail moar proc';
}

done-testing