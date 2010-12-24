
=head1 NAME

App::Pebble::Source::DateTime - Date/time source, i.e. parsing of strings
into DateTime objects.

=cut

package App::Pebble::Source::DateTime;
use Moose;
use MooseX::Method::Signatures;

use DateTimeX::Easy;

# Needed by Pebble::Object and JSON::XS
sub DateTime::TO_JSON {
    my $self = shift;
    "$self";
}

method parse($class: $dt_string) {
    return DateTimeX::Easy->new( $dt_string );
}

1;
