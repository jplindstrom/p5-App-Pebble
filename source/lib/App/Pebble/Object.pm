
=head1 NAME

App::Pebble::Object - Base class for Pebble objects

=cut

package App::Pebble::Object;

use warnings;
use strict;

use IO::Pipeline;
use Moose;
use JSON::XS;

sub _meta_class {
    my $class = shift;
    my ($has) = @_;
    @$has or die( "Can't define class: No field names provided (with 'has')\n" );

    my $meta_class = Moose::Meta::Class->create_anon_class(
        superclasses => [ "App::Pebble::Object" ],
    );
    for my $field (@$has) {
        $meta_class->add_attribute( $field => ( is => 'rw' ) );
    }    

    return $meta_class;
}

sub _values_to_fields {
    my $class = shift;
    my ($has, $values) = @_;

    my $arg_value;
    for my $field ( @$has ) {
        $arg_value->{ $field } = shift( @$values );
    }

    return $arg_value;
}

sub split {
    my $class = shift;
    my ($args) = @_;
    my $split = $args->{split} || qr/\s+/; 
    my $has   = $args->{has}   || [];

    my $meta_class = $class->_meta_class( $has );

    return pmap { $meta_class->new_object( $class->_split_line( $split, $has, $_ ) ) };
}

sub _split_line {
    my $class = shift;
    my ( $split, $has, $line ) = @_;
    my @values = split( $split, $line );
    return $class->_values_to_fields( $has, \@values );
}

sub match {
    my $class = shift;
    my ($args) = @_;
    my $regex = $args->{regex} or die( "No regex provided\n" );
    my $has = $args->{has} || [];

    my $meta_class = $class->_meta_class( $has );

    return pmap {
        my $args = $class->_match_line( $regex, $has, $_ );
        $args ? $meta_class->new_object( $args ) : ();
    };
}

sub _match_line {
    my $class = shift;
    my ( $regex, $has, $line ) = @_;
    my @values = ( $line =~ $regex ) or return undef;
    return $class->_values_to_fields( $has, \@values );
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

# maybe, not sure about this one at all
sub fields {
    my $self = shift;
    my (@fields) = @_;
    join( ", ", map { $self->$_ } @fields );
}
 
use overload q|""| => \&as_json, fallback => 1;

no Moose;

1;
