
=head1 NAME

App::Pebble::Render::CSV - Render CSV output

=cut

package App::Pebble::Render::CSV;
use Moose;
extends "App::Pebble::Render";

use IO::Pipeline;
use Text::CSV_XS;

use Data::Dumper;

sub render {
    my $class = shift;
    my ($args) = @_;
    my $fields = $args->{fields};

    my $csv = $class->get_csv( $args );

    my $pending_first_line = 1;
    return pmap {
        my ($pebble) = @_;

        $fields ||= [
            sort grep { defined } map { $_->accessor } $pebble->meta->get_all_attributes
        ];

        my @lines;
        if( $pending_first_line ) {
            $pending_first_line = 0;
            $csv->combine( @$fields )
                    or die( "Could not create top CSV row with column names\n" );
            push( @lines, $csv->string );
        }

        $csv->combine( map { $pebble->$_ } @$fields )
                or die( "Could not write CSV row for Pebble:\n$pebble" );
        push( @lines, $csv->string );

        @lines;
    };
}

sub get_csv {
    my $class = shift;
    return Text::CSV_XS->new ({ binary => 1 })
            or die "Cannot use CSV: ".Text::CSV->error_diag ();
    
}
1;
