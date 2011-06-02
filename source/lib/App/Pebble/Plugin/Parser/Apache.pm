
=head1 NAME

App::Pebble::Plugin::Parser::Apache - Parse Apache logs (access, etc)

=cut

package App::Pebble::Plugin::Parser::Apache;
use Moose;
use Method::Signatures;

use App::Pebble::Modifier::Pipeline;
use App::Pebble::Modifier::Object;
use App::Pebble::Plugin::Parser::Regex;

method access($class: :$parse_dates = 0) {

  my $core_pipeline = sub {

    # 212.58.246.39 - - [07/Apr/2011:01:00:02 +0100] "GET /blah/user_id/845d08b HTTP/1.1" 200 23724 "-" "useragent" 163527 3710
    App::Pebble::Plugin::Parser::Regex->match(
      regex => qr|^ ([\d.]+) \s+ - \s+ - \s+ \[ (.+?) \] \s+ "(.+?) \s HTTP/[\d.]+" \s (\d+) \s \d+ \s ".+?" \s "(.+?)"|x,
      has   => ["ip", "timestamp_str", "url", "code", "useragent" ],
    )
  };
  $parse_dates or return $core_pipeline->();

  return
      $core_pipeline->()
      | oreplace {
        timestamp_str => { timestamp => S::DateTime->parse( $_->timestamp_str ) },
      };
}

1;
