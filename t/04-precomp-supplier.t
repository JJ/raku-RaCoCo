use Test;
use lib 'lib';
use lib 't/lib';
use App::Racoco::Coverable::Precomp::PrecompSupplier;
use App::Racoco::Coverable::Precomp::PrecompLookup;
use App::Racoco::Coverable::Precomp::Precompiler;
use App::Racoco::ModuleNames;
use App::Racoco::Paths;
use Fixture;
use TestResources;
use TestHelper;

plan 3;

my ($lib, $file-name, $proc, $supplier);
sub setup($file, $lib-name) {
	plan $*plan;
	TestResources::prepare($*subtest);
	$lib = TestResources::exam-directory.add($lib-name);
	$file-name = $file;
	$proc = Fixture::realProc;
	$supplier = PrecompSupplierReal.new(
		lookup => PrecompLookup.new(:$lib, compiler-id => -> {Fixture::compiler-id}),
		precompiler => Precompiler.new(:$lib, :raku<raku>, :$proc)
	);
}

'01-supply-precomp-in-lib'.&test(:2plan, {
	setup('Module.rakumod', 'lib');
	my $expected = lib-precomp-path(:$lib)
		.add(Fixture::compiler-id()).add(file-precomp-path(:$lib, path => $file-name)).IO;
	is $supplier.supply(:$file-name), $expected, 'precomp ok';
	nok $proc.c, 'cold proc';
});

'02-supply-compile'.&test(:2plan, {
	setup('Module.rakumod', 'lib');
	my $expected = our-precomp-path(:$lib).add(file-precomp-path(:$lib, path => $file-name)).IO;
	is $supplier.supply(:$file-name), $expected, 'compile ok';
	ok $proc.c, 'hot proc';
});

'03-our-precomp'.&test(:2plan, {
	setup('Module.rakumod', 'lib');
	my $expected = our-precomp-path(:$lib).add(file-precomp-path(:$lib, path => $file-name)).IO;
	is $supplier.supply(:$file-name), $expected, 'compile ok';
	nok $proc.c, 'cold proc';
});

done-testing