unit module Racoco::Report::Report;

enum COLOR is export <GREEN RED PURPLE>;

sub percent($a, $b --> Real) {
  return 100 if $b == 0;
  min(100, (($a / $b) * 100 * 10).Int / 10);
}

class FileReportData is export {
  has Str $.file-name;
  has Set $.green;
  has Set $.red;
  has Set $.purple;

  method percent(--> Real) {
    my $covered = self.covered();
    my $coverable = self.coverable();
    return 100 if $coverable == 0;
    percent($covered, $coverable);
  }

  method color(Int :$line --> COLOR) {
    return GREEN if $!green{$line};
    return RED if $!red{$line};
    return PURPLE if $!purple{$line};
    Nil
  }

  method covered(--> Int) {
    $!green.elems + $!purple.elems
  }

  method coverable(--> Int) {
    $!green.elems + $!red.elems
  }
}

class Report is export {
  has FileReportData %!data;

  submethod BUILD(:@fileReportData) {
    for @fileReportData {
      %!data{$_.file-name} = $_
    };
  }

  method percent(--> Real) {
    return 100 if %!data.elems == 0;
    my ($covered, $coverable) = 0, 0;
    %!data.values.map({
      $covered += .covered;
      $coverable += .coverable;
    });
    percent($covered, $coverable)
  }

  method data(:$file-name --> FileReportData) {
    %!data{$file-name}
  }

  method all-data(--> Positional) {
    %!data.values.sort(*.file-name).List
  }
}