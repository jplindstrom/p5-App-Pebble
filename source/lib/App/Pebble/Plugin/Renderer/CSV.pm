
=head1 NAME

App::Pebble::Plugin::Render::CSV - Render CSV output

=cut

package App::Pebble::Plugin::Renderer::CSV;
use Moose;

use Method::Signatures;

use IO::Pipeline;
use Text::CSV_XS;

use Data::Dumper;

method render($class: $args?) {
    my $fields = $args->{fields};
    $fields && ref( $fields ) ne "ARRAY" and $fields = [ $fields ];

    my $csv = $class->get_csv( $args );

    my $pending_first_line = 1;
    return pmap {
        my ($pebble) = @_;

        $fields ||= [
            sort grep { defined } map { $_->accessor } $pebble->meta->get_all_attributes
        ];
        #TODO: validate field names

        my @lines;
        if( $pending_first_line ) {
            $pending_first_line = 0;
            $csv->combine( @$fields )
                    or die( "Could not create top CSV row with column names\n" );
            push( @lines, $csv->string . "\n" );
        }

        $csv->combine( map { $pebble->$_ } @$fields )
                or die( "Could not write CSV row for Pebble:\n$pebble" );
        push( @lines, $csv->string . "\n" );

        @lines;
    };
}

method get_csv($class: $args?) {
    return Text::CSV_XS->new ({ binary => 1 })
            or die "Cannot use CSV: ".Text::CSV->error_diag ();
    
}
1;
