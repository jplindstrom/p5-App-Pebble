
=head1 NAME

App::Pebble::Object - Base class for Pebble objects

=cut

package App::Pebble::Object;

use warnings;
use strict;

use IO::Pipeline;
use Moose;
use JSON::XS;

sub split {
    my $class = shift;
    my ($args) = @_;
    my $split = $args->{split} || qr/\s+/; 
    my $has   = $args->{has}   || [];

    my $meta_class = Moose::Meta::Class->create_anon_class(
        superclasses => [ "App::Pebble::Object" ],
    );

    for my $field (@$has) {
        $meta_class->add_attribute( $field => ( is => 'rw' ) );
    }

    return pmap { $meta_class->new_object( $class->_split_line( $split, $has, $_ ) ) };
}

sub _split_line {
    my $class = shift;
    my ( $split, $has, $line ) = @_;

    my @values = split( $split, $line );
    my $arg_value;
    for my $field ( @$has ) {
        $arg_value->{ $field } = shift( @values );
    }
    use Data::Dumper;
    return $arg_value;
}

sub as_json {
    my $self = shift;
    my %attr = %$self;
    delete $attr{__MOP__};

    my $encoder = JSON::XS->new->pretty;
    my $json = $encoder->encode( \%attr );
    chomp( $json );

    return $json;
}

use overload q|""| => \&as_json, fallback => 1;

1;
