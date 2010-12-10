
=head1 NAME

App::Pebble::Parse - Base class for Pebble parsers

=cut

package App::Pebble::Parse;
use Moose;
use MooseX::Method::Signatures;

use IO::Pipeline;
use JSON::XS;

use Pebble::Object::Class;

method _values_to_fields($class: $has, $values) {
    my $arg_value;
    for my $field ( @$has ) {
        $arg_value->{ $field } = shift( @$values );
    }

    return $arg_value;
}

#TODO: shoud really be in Parse::Regex or something like that, with
#these methods exposed in this, so R->xxx works.
method split($class: $args) {
    my $split = $args->{split} || qr/\s+/; 
    my $has   = $args->{has}   || [];

    my $meta_class = Pebble::Object::Class->new_meta_class( $has );

    return pmap { $meta_class->new_object( $class->_split_line( $split, $has, $_ ) ) };
}

method _split_line($class: $split, $has, $line) {
    my @values = split( $split, $line );
    return $class->_values_to_fields( $has, \@values );
}

method match($class: :$regex, :$has?) {
    $regex or die( "No regex provided\n" );
    $has ||= []; #TODO: should also die, can't create an object without

    my $meta_class = Pebble::Object::Class->new_meta_class( $has );

    return pmap {
        my $args = $class->_match_line( $regex, $has, $_ );
        $args ? $meta_class->new_object( $args ) : ();
    };
}

method _match_line($class: $regex, $has, $line) {
    my @values = ( $line =~ $regex ) or return undef;
    return $class->_values_to_fields( $has, \@values );
}

1;
