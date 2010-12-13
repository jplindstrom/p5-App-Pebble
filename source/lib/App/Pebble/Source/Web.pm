
=head1 NAME

App::Pebble::Source::Web - Web source, e.g. HTTP get

=cut

package App::Pebble::Source::Web;
use Moose;

use MooseX::Method::Signatures;

use URI::Fetch;
use Data::Dumper;

method get($class: $url) {
    require App::Pebble;

    warn "START ($url)\n";
    my $res = URI::Fetch->fetch( $url, Cache => App::Pebble->cache );
    warn "END\n";
    return $res->content;
}

1;
