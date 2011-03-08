# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::Vis - Visualization source

=cut

package App::Pebble::Plugin::Source::Vis;
use Moose;

use Method::Signatures;

use App::Pebble::Plugin::Source::Statistics;
use App::Pebble::Modifier::Object;


=head1 METHODS

=head2 text_bar( $attribute, $char = "#" ) : $bar_sized_value

Return a bar of $char with length $value, e.g. 5, "*" returns

  *****

Useful to visualize the size of $value.

=cut

method text_bar($class: $attribute, :$char = "#" ) {
    # validate $attribute
    my $value = $_->$attribute;
    return $char x $value;
}

=head2 oadd_size($class: $of_attribute, :$bar_attribute = ${of_attribute}_size, :$max_size = 10, :$char = "#") : $pipeline_segment

Return an oadd {} pipeline segment which adds a new attribute with a
I<text bar> representing the relative I<size> of each value
$of_attribute.

    onew { temperature => int( rand( 100 )) }
    | S::Statistics->oadd_size_bar( "temperature" )

  | temperature | temperature_size |
  | 50          | #####            |
  | 100         | ##########       |
  | 66          | #######          |
  | 5           | #                |

=cut

method oadd_size($class: $of_attribute, :$bar_attribute?, :$max_size = 10, :$char = "#" ) {
    $bar_attribute ||= "${of_attribute}_size";
    my $temp_scale_attribute = "${of_attribute}__pebble_scale";

    return 
        App::Pebble::Plugin::Source::Statistics->oadd_scale(
            $of_attribute,
            new_attribute => $temp_scale_attribute,
            new_max_value => $max_size,
        )
        | oadd {
            $bar_attribute => do { $class->text_bar( $temp_scale_attribute, char => $char ) }
        }
        | odelete { $temp_scale_attribute };
}

1;
