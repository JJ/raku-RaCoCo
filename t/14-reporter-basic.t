use Test;
use lib 'lib';
use lib 't/lib';
use App::Racoco::Report::Report;
use App::Racoco::Report::ReporterBasic;
use App::Racoco::Paths;
use TestResources;

plan 1;

my ($lib, $report-path, $subtest);
sub setup($lib-name, :$subtest, :$plan!) {
	plan $plan;
	TestResources::prepare($subtest);
	$lib = TestResources::exam-directory.add($lib-name);
	$report-path = report-basic-path(:$lib);
}

$subtest = '01-read-from-file';
subtest $subtest, {
	setup('lib', :$subtest, :1plan);
  my $reporter = ReporterBasic.read(:$lib);
	my $expect = Report.new(fileReportData => (
		FileReportData.new(:file-name<AllGreen>, green => (1, 3, 5), red => (), purple => ()),
		FileReportData.new(:file-name<AllRed>, green => (), red => (2, 4, 6), purple => ()),
		FileReportData.new(:file-name<GreenRed>, green => 7, red => 8, purple => ()),
		FileReportData.new(:file-name<WithPurple>, green => 1, red => (2, 4), purple => 3),
		FileReportData.new(:file-name<Empty>, green => (), red => (), purple => ()),
	));
  ok $reporter.report eqv $expect, 'read correct data';
}


#my ($sources, $lib) = TmpDir::create-tmp-lib('racoco-test');
#my $report-path = report-basic-path(:$lib);
#
#my %coverable-lines = %{
#  'AllGreen' => (1, 3, 5).Set,
#  'AllRed' => (2, 4, 6).Set,
#  'GreenRed' => (7, 8),
#  'WithPurple' => (1, 2, 4).Set,
#  'Empty' => ().Set
#}
#
#my %covered-lines = %{
#  'AllGreen' => (1, 3, 5).Set,
#  'GreenRed' => (7),
#  'WithPurple' => (1, 3).Set,
#}
#
#my $report-content = q:to/END/.trim;

#  END
#

#
#{
#  my $reporter = ReporterBasic.make-from-data(:%coverable-lines, :%covered-lines);
#  ok $reporter.report eqv $report-expect, 'make correct data';
#  my $path = $reporter.write(:$lib);
#  is $path, $report-path, 'correct report path';
#  is $report-path.slurp, $report-content, 'write base report ok';
#}
#

#
#{
#  my ($, $lib) = TmpDir::create-tmp-lib('racoco-test-not-exists-report');
#  throws-like { ReporterBasic.read(:$lib) }, App::Racoco::X::CannotReadReport,
#    'no report file, no reporter', message => /$lib/;
#}

done-testing