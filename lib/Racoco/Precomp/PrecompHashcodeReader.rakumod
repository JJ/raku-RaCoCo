unit module Racoco::Precomp::PrecompHashcodeReader;

use Racoco::RunProc;

role PrecompHashcodeReader is export {
  method read(IO() :$path --> Str) { ... }
}

class PrecompHashcodeReaderReal does PrecompHashcodeReader is export {
  method read(IO() :$path --> Str) {
    my $h = $path.open :r;
    LEAVE { .close with $h }
    $h.get
  }
}