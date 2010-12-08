
=head1 NAME

App::Pebble::Object - Base class for Pebble objects

=cut

package App::Pebble::Object;
use Moose;
use MooseX::Method::Signatures;

use IO::Pipeline;
use JSON::XS;

#TODO: cache the metaclass creation on join("-", sort @$has)
method new_meta_class($class: $has) {
    @$has or die( "Can't define class: No field names provided (with 'has')\n" );

    my $meta_class = Moose::Meta::Class->create_anon_class(
        superclasses => [ "App::Pebble::Object" ],
    );
    for my $field (@$has) {
        $meta_class->add_attribute( $field => ( is => 'rw' ) );
    }    

    return $meta_class;
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

1;
