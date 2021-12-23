use App::Racoco::Report::Reporter;
use App::Racoco::Report::DataPart;
use App::Racoco::Report::Data;
use App::Racoco::Properties;
use App::Racoco::Report::ReporterCoveralls::MD5;
use App::Racoco::Report::ReporterCoveralls::Git;
use App::Racoco::Report::ReporterCoveralls::Factory;

unit class App::Racoco::Report::ReporterCoveralls does Reporter is export;

has MD5 $!md5 = Factory::create-md5();
has Git $!git = Git.new;

method do(IO::Path:D :$lib, Data:D :$data, Properties:D :$properties) {
	# 1 collect all configurations
	# 2 collect data to send
	# 3 send
}

method make-source-files-json(:$lib, :$data) {
	$data.get-all-parts.map(-> $part {
		my $content = $lib.add($part.file-name).slurp;
		my $coverage = self.coverage-line(:$lib, :$content, :$part)
	}).join(",\n");
}

method coverage-line(:$lib, :$content, :$part) {
	my $lib-name = $lib.basename;
	my $lines = $content.lines.elems;
	my $name = q/"name":"/ ~ $lib-name ~ '/' ~ $part.file-name ~ '",';
	my $source-digest = q/"source_digest":"/ ~ $!md5.md5($content) ~ '",';
	my $coverage = q/"coverage":[/ ~
		(1..$lines).map(-> $line { $part.hit-times-of(:$line) // 'null' }).join(',') ~ ']';
	join "\n", '{', $name, $source-digest, $coverage, '}';
}

method make-git(:$properties) {
	my $remote := $!git.get-git(:$properties, :remote).first;
	qq:to/END/.trim
	\{
	"git":\{
		"head":\{
			"id":"{$!git.get-git(:$properties, :hash)}",
			"author_name":"{$!git.get-git(:$properties, :author)}",
			"author_email":"{$!git.get-git(:$properties, :email)}",
			"committer_name":"{$!git.get-git(:$properties, :committer)}",
			"committer_email":"{$!git.get-git(:$properties, :committer-email)}",
			"message":"{$!git.get-git(:$properties, :message)}"
		},
		"branch":"{$!git.get-git(:$properties, :branch)}",
		"remotes": [
			\{
				"name":"{$remote.key}",
				"url": "{$remote.value}"
			}
		]
	}
	}
	END
}

method get-repo-token(:$p!) {
	return $p.env-only('GITHUB_TOKEN') if $.is-github(:$p);
	$p.env-only('COVERALLS_REPO_TOKEN') //
	$p.property('repo_token') //
	''
}

method get-service-name(:$p) {
	return $p.property('github_service_name') // 'github-actions' if $.is-github(:$p);
	$p.env-only('COVERALLS_SERVICE_NAME') //
	$p.property('service_name') //
	''
}

method get-service-number(:$p) {
	return $p.env-only('GITHUB_RUN_ID') if $.is-github(:$p);
	return $p.env-only('CI_PIPELINE_IID') if $.is-gitlab(:$p);
	$p.env-only('COVERALLS_SERVICE_NUMBER') //
	$p.property('service_number') //
	''
}

method is-github(:$p!) {
	$p.env-only('GITHUB_ACTIONS').defined
}

method is-gitlab(:$p!) {
	$p.env-only('GITLAB_CI').defined
}