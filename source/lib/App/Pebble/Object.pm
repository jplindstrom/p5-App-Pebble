
=head1 NAME

App::Pebble::Object - Base class for Pebble objects

=cut

package App::Pebble::Object;

use warnings;
use strict;

use IO::Pipeline;
use Moose;

sub split {
    my $self = shift;
    my ($split, $has) = @_{qw/ split has /};
    $split ||= qr/\s+/;
    $has ||= [];

    my $meta_class = Moose::Meta::Class->create_anon_class(
        superclasses => [ "App::Pebble::Object" ],
    );

    for my $field (@$has) {
        $meta_class->add_attribute( $field => ( is => 'rw' ) );
    }

    return pmap { $meta_class->new_object( $self->_split_line( $split, $has, $_ ) ) };
}

sub _split_line {
    my $self = shift;
    my ( $split, $has, $line ) = @_;

    my @values = split( $split, $line );
    my $arg_value;
    for my $field ( @$has ) {
        $arg_value->{ $field } = shift( @values );
    }

    return $arg_value;
}

sub stringify {
    "hello there";
}

use overload q|''| => \&stringify, fallback => 1;

1;
