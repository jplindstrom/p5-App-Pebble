
=head1 NAME

App::Pebble::Render::Graph::Basic - Render output as basic (good
defaults, little flexibility) graph using L<Chart::Clicker>.

If you need more specific rendering, you should probably write another
renderer with a more flexible API.

=cut

package App::Pebble::Render::Graph::Basic;
use Moose;
extends "App::Pebble::Render";

use MooseX::Method::Signatures;

use Data::Dumper;
use IO::Pipeline;
use Chart::Clicker;
use Chart::Clicker::Data::DataSet;
use Chart::Clicker::Data::Series;
use Chart::Clicker::Axis::DateTime;
# use Chart::Clicker::Context;
# use Chart::Clicker::Data::Marker;
# use Geometry::Primitive::Rectangle;
# use Graphics::Color::RGB;

method needs_pool { 1 }

method render($class: $args?) {
    my @items;
    my $height = $args->{height} || 250;
    my $width = $args->{width} || 500;
    my $title = $args->{title} || "";
    my $x = $args->{x};
    my $y = $args->{y} or die( "Graph::Basic renderer missing 'y' parameter\n" );
    ref( $y ) ne "ARRAY" and $y = [ $y ];
    my $type = $args->{type} || "Bar";

    my $cc = Chart::Clicker->new( width => $width, height => $height );

    $title and $cc->title->text( $title );
    $cc->title->padding->bottom( 5 );
    my $chart_type = "Chart::Clicker::Renderer::$type";
    eval "use $chart_type";
    $@ and die( "Could not use the Chart::Basic 'type' ($type)\n$@" );
    my $ctx = $cc->get_context('default');
    $ctx->renderer( $chart_type->new( opacity => .8 ) );

    my $keys = [ ];
    my $key_values = { };
    my $count = 0;

    my $keys_are_all_datetimes = 1;

    return ppool(
      sub {
          $count++;

          no warnings;
          my $x_value = $x ? $_->$x : $count;

          if( blessed( $x_value ) && $x_value->isa( "DateTime" ) ) {
              $x_value = $x_value->epoch;
          } else {
              $keys_are_all_datetimes = 0;
          }
              
          if( $class->is_numeric( $x_value ) ) {
              for my $cur_y ( @$y ) {
                  my $y_value = $_->$cur_y;
                  $class->is_numeric( $y_value ) or next; # Must be numerical

                  push @{$key_values->{ $cur_y }->{keys}}, $x_value;
                  push @{$key_values->{ $cur_y }->{values}}, $y_value;
              }
          }

          ();
      },
      sub {
          if( $keys_are_all_datetimes ) {
              $ctx->domain_axis(
                  Chart::Clicker::Axis::DateTime->new(
                      position    => "bottom",
                      orientation => "horizontal",
                      staggered   => 1,
                  ),
              );
          }
          
          $cc->add_to_datasets(
              Chart::Clicker::Data::DataSet->new(
                  series => [
                      map {
                          Chart::Clicker::Data::Series->new(
                              name => $_,
                              keys   => $key_values->{ $_ }->{keys},
                              values => $key_values->{ $_ }->{values},
                          ),
                      }
                      @$y
                  ],
              ),
          );

          $cc->draw;
          $cc->rendered_data;
      },
  );
}

method is_numeric($class: $value) {
    defined $value or return 0;
    return $value =~ /^-?[\d.]+$/;
}

1;
