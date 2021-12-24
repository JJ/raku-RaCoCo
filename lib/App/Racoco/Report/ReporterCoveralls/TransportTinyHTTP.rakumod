use App::Racoco::Report::ReporterCoveralls::Transport;
use HTTP::Tiny;

unit class App::Racoco::Report::ReporterCoveralls::TransportTinyHTTP
	does Transport
	is export;

has $.host is built(False) = 'coveralls.io';

class Foo is IO::Path {
	has $.content;
	method slurp(|c) {
		$!content.encode
	}
	method basename(|c) {
		'json_file'
	}
	method set($content) {
		$!content = $content;
		self
	}
}



method send(Str:D $obj, :$uri --> Str) {
	my $response = HTTP::Tiny.new.post:
		($uri // self.uri()),
		content => %(json_file => Foo.new($*CWD).set($obj));
	my $content = $response<content>.decode;
	fail $response<status> ~ "$?NL" ~ $content unless $response<success>;
	self.parse-responce-url($content)
}

# {"message":"Job #1618708989.1","url":"https://coveralls.io/jobs/92040948"}
method parse-job-url($response --> Str) {
	$response.match(/'https://coveralls_io' <-["]>+/) // ''
}