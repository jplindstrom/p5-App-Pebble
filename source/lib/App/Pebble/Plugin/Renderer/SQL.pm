
=head1 NAME

App::Pebble::Plugin::Render::SQL - Render SQL statements

=cut

package App::Pebble::Plugin::Renderer::SQL;
use Moose;

use Method::Signatures;

use IO::Pipeline;

method insert($class: :$table, :$columns?) {
    $columns && ref( $columns ) ne "ARRAY" and $columns = [ $columns ];

    return pmap {
        my ($pebble) = @_;

        ###TODO: DRY from CSV
        $columns ||= [
            sort grep { defined } map { $_->accessor } $pebble->meta->get_all_attributes
        ];
        #TODO: validate field names

        my $statement = "INSERT INTO $table (" . join( ", ", @$columns ) . ") VALUES ()";

        $statement;
    };
}

1;
