
=head1 NAME

App::Pebble::Source::Web - Web source, e.g. HTTP get

=cut

package App::Pebble::Source::Web;
use Moose;

use MooseX::Method::Signatures;

use LWP::UserAgent::WithCache;
use Data::Dumper;

method get_response($class: $url) {
    require App::Pebble;
warn "Getting ($url)\n";
    my $ua = LWP::UserAgent::WithCache->new();
    $ua->{cache} = App::Pebble->cache; # so sue me, provide a useful interface then

    # Ignore the response "expires" header, always use cache if
    # present
    no warnings "once";
    local *GLOBAL::time = sub { 0 };
    my $res = $ua->get( $url ) or return undef;
    return $res;
}

method get($class: $url) {
    my $res = $class->get_response( $url );
    $res or return undef;
#    warn "LENGTH ($url): " . length($res->content) . "\n";
    return $res->content;
}

1;
