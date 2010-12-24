
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

method _index_values_to_fields($class: $has_index, $values) {
    my $arg_value;
    for my $field ( keys %$has_index ) {
        my $index = $has_index->{ $field };
        $arg_value->{ $field } = $values->[ $index ];
    }

    return $arg_value;
}

#TODO: don't use a hashref for the args

#TODO: shoud really be in Parse::Regex or something like that, with
#these methods exposed in this, so R->xxx works.
method split($class: $args) {
    my $split = $args->{split} || qr/\s+/; 
    my $has   = $args->{has}   || [];

    my $has_index;
    if( ref $has eq "HASH" ) {
        $has_index = $has;
        $has = [ sort keys %$has_index ];
    }
    (ref $has eq "ARRAY") or $has = [ $has ];  ###TODO: refactor

    my $meta_class = Pebble::Object::Class->new_meta_class( $has );

    return $has_index
      ? pmap { $meta_class->new_object( $class->_split_line_index( $split, $has_index, $_ ) ) }
      : pmap { $meta_class->new_object( $class->_split_line( $split, $has, $_ ) ) };
}

method _split_line($class: $split, $has, $line) {
    my @values = split( $split, $line );
    return $class->_values_to_fields( $has, \@values );
}

method _split_line_index($class: $split, $has_index, $line) {
    my @values = split( $split, $line );
    return $class->_index_values_to_fields( $has_index, \@values );
}

method match($class: :$regex, :$has?) {
    $regex or die( "No regex provided\n" );
    $has ||= []; #TODO: should also die, can't create an object without
    (ref $has eq "ARRAY") or $has = [ $has ];  ###TODO: refactor

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
