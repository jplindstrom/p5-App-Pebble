# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::Statistics - Statistics source,
i.e. basic statistical transformations.

=cut

package App::Pebble::Plugin::Source::Statistics;
use Moose;

use Method::Signatures;
use List::Util qw/ max /;

use App::Pebble::Modifier::Pipeline;
use Pebble::Object::Class;

=head1 METHODS

=head2 percent_of( $what_attribute => ( $attribute | @$attributes ) ) : %percent_attribute_value

Shortcut for turning

  S::Statistics->percent_of( total => [qw/ failures retries /] )

into

  failures_pct  => $_->failures  / ( $_->total || 1 ),
  retries_pct   => $_->retries   / ( $_->total || 1 ),

The naming convention for the new attributes is ${attribute}_pct.

Useful e.g. like this:

  oadd { S::Statistics->percent_of( total => [qw/ failures retries /] ) }

Can also be used with only one attribute

  S::Statistics->percent_of( total => "retries" )

=cut

method percent_of($class: $what_attribute, $percent_of_attributes ) {
    ref $percent_of_attributes eq "ARRAY" or $percent_of_attributes = [ $percent_of_attributes ];

    my $pebble = $_;
    return
        map { ( "${_}_pct"  => $pebble->$_  / ( $pebble->$what_attribute || 1 ) ) }
        @$percent_of_attributes;
}

=head2 oadd_scale($class: $of_attribute, :$new_attribute = $of_attribute, :$new_max_value = 10 ) : $pipeline_segment

Return an oadd {} pipeline segment which adds a new attribute with a
value scaled up or down to $new_max_value.

    onew { temperature => int( rand( 500 )) }
    | S::Statistics->oadd_scale( "temperature", "temp_norm", 30 )

=cut

method oadd_scale($class: $of_attribute, :$new_attribute = $of_attribute, :$new_max_value = 10 ) {
    my @pebbles;
    # validate $of_attribute

    ###TODO: use data types to deal with ints

    my $max_value;
    ppool(
        sub {
            push( @pebbles, $_ );
            my $value = $_->$of_attribute;
            if( defined $max_value ) {
                $max_value = max( $max_value, $value );
            }
            else {
                $max_value = $value;
            }
            return ();
        },
        sub {
            my $scale = $new_max_value / $max_value;

            my @scaled_pebbles;
            while( my $pebble = shift @pebbles ) {
                push(
                    @scaled_pebbles,
                    Pebble::Object::Class->modify(
                        -object => $pebble,
                        -add    => {
                            ###TODO: not always int()
                            $new_attribute => int( $pebble->$of_attribute * $scale ),
                        },
                    ),
                );
            }

            return @scaled_pebbles;
        }
    );
}

1;
