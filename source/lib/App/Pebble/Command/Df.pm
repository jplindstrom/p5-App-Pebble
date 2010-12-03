
=head1 NAME

App::Pebble::Command::Df - Command to run "df"

=cut

package App::Pebble::Command::df;
use Moose;
use App::Pebble::Object;

sub name    { "df" }
sub command { "df" }

sub parser {
    my $class = shift;
    my ($args) = @_;

    return App::Pebble::Object->match({
        regex =>  qr/ (.+?) \s+  (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+)% \s+ (.+)      $/x,
        has   => [qw/ filesystem blocks    used      available capacity   mounted_on /]
    });
}

1;
