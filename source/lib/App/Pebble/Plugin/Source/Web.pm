
=head1 NAME

App::Pebble::Plugin::Source::Web - Web source, e.g. HTTP get

=cut

package App::Pebble::Plugin::Source::Web;
use Moose;
use MooseX::ClassAttribute;

use Method::Signatures;

use LWP::UserAgent::WithCache;
use HTTP::Cookies;
use Data::Dumper;

use App::Pebble::Log qw/ $log /;

class_has cookie_jar => (
  is      => "rw",
  default => sub { HTTP::Cookies->new( {} ) }, # Don't persist across pebble.pl invocations
);

method get_response($class: $url, :$no_cache = 0) {
    require App::Pebble;
    $log->info( "Getting ($url)" );
    my $ua = LWP::UserAgent::WithCache->new();
    $ua->env_proxy;
    $ua->{cache} = # so sue me, provide a useful interface then
        $no_cache
        ? App::Pebble->null_cache
        : App::Pebble->cache;
    $ua->cookie_jar( $class->cookie_jar );

    # Ignore the response "expires" header, always use cache if
    # present
    no warnings "once";
    local *GLOBAL::time = sub { 0 };

    my $res = $ua->get( $url ) or return undef;
    return $res;
}

method get($class: $url, :$no_cache = 0) {
    my $res = $class->get_response( $url, no_cache => $no_cache );
    $res or return undef;
#    warn "LENGTH ($url): " . length($res->content) . "\n";
    return $res->content;
}

1;
