
=head1 NAME

App::Pebble::Object - Base class for Pebble objects

=cut

package App::Pebble::Object;
use Moose;
use MooseX::Method::Signatures;

use IO::Pipeline;
use JSON::XS;

method _meta_class($class: $has) {
    @$has or die( "Can't define class: No field names provided (with 'has')\n" );

    my $meta_class = Moose::Meta::Class->create_anon_class(
        superclasses => [ "App::Pebble::Object" ],
    );
    for my $field (@$has) {
        $meta_class->add_attribute( $field => ( is => 'rw' ) );
    }    

    return $meta_class;
}

method _values_to_fields($class: $has, $values) {
    my $arg_value;
    for my $field ( @$has ) {
        $arg_value->{ $field } = shift( @$values );
    }

    return $arg_value;
}

method split($class: $args) {
    my $split = $args->{split} || qr/\s+/; 
    my $has   = $args->{has}   || [];

    my $meta_class = $class->_meta_class( $has );

    return pmap { $meta_class->new_object( $class->_split_line( $split, $has, $_ ) ) };
}

method _split_line($class: $split, $has, $line) {
    my @values = split( $split, $line );
    return $class->_values_to_fields( $has, \@values );
}

method match($class: $args) {
    my $regex = $args->{regex} or die( "No regex provided\n" );
    my $has = $args->{has} || [];

    my $meta_class = $class->_meta_class( $has );

    return pmap {
        my $args = $class->_match_line( $regex, $has, $_ );
        $args ? $meta_class->new_object( $args ) : ();
    };
}

method _match_line($class: $regex, $has, $line) {
    my @values = ( $line =~ $regex ) or return undef;
    return $class->_values_to_fields( $has, \@values );
}

method as_json {
    my $encoder = JSON::XS->new; #->pretty;
    my $json = $encoder->encode( $self->as_hashref );
    chomp( $json );

    return "$json\n";
}

method as_hashref {
    my %attr = %$self;
    delete $attr{__MOP__};
    delete $attr{"<<MOP>>"};
    return \%attr;
}

# maybe, not sure about this one at all
method fields(@fields) {
    join( ", ", map { $self->$_ } @fields );
}
 
use overload q|""| => \&as_json, fallback => 1;

no Moose;

1;
