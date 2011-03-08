# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Render::HTML::List::Image - Render HTML::List::Image output

=cut

package App::Pebble::Plugin::Renderer::HTML::List::Image;
use Moose;

use Method::Signatures;

use IO::Pipeline;
use Data::Dumper;
use CGI qw/:standard/;
use File::Slurp qw/ write_file /;

method render($class: $file_name_field, $file?) {
  $file and ( $file =~ /\.html$/ or $file .= ".html" );

  # validate $file_name_field

  my @items;
  return ppool(
      sub { push( @items, $_ ); () },
      sub {
          my $html = start_html("Image List");
          $html .= join(
              "\n",
              map {
                  my $title = $_->$file_name_field;
                  $title =~ s/\.\w+$//s;
                  $title =~ s/_+/ /gsm;
                  h3( $title ), img { src => $_->$file_name_field, alt => $title };
              }
              @items
          );
          $html .= end_html();

          if( $file ) {
              write_file( $file, { binmode => ":raw" }, $html );
              return ();
          }
          else {
              return $html;
          }
      },
  );
  
  
}

1;
