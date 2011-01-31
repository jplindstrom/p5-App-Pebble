
=head1 NAME

App::Pebble::Plugin::Render::SQL - Render SQL statements

=cut

package App::Pebble::Plugin::Renderer::SQL;
use Moose;

use Method::Signatures;

use IO::Pipeline;

method insert($class: :$table, :$columns?) {
    $columns && ref( $columns ) ne "ARRAY" and $columns = [ $columns ];
    ###TODO: statement_terminator = ";"
    ###TODO: statement_separator = "";  # can be "\n\n"
    ###TODO: sql_dialect, or DBD or somethign to provide good defaults
    ###for quoting tables, column names and values

    my $column_quoted = {};
    @$columns = map {
        if( s/ ( \w+ ) \s* (\[ \s* (\w+) \s* \])/$1/x ) {
            my $datatype = $3;
            $datatype ne "Num" and $column_quoted->{ $_ } = 1;
            ###TODO: needs a lot more work obviously, but this way we
            ###get DateTime, etc quoted properly
        }
        $_;
    } @$columns;

    my $quoted_sub = sub {
        my ($attribute, $value) = @_;
        $column_quoted->{ $attribute } and return qq/"$value"/;
        return $value;
    };

    return pmap {
        my ($pebble) = @_;

        ###TODO: DRY from CSV
        $columns ||= [
            sort grep { defined } map { $_->accessor } $pebble->meta->get_all_attributes
        ];
        #TODO: validate field names

        my $statement = "INSERT INTO $table ("
            . join( ", ", @$columns )
            . ") VALUES ("
            . join( ", ", map { $quoted_sub->( $_ => $pebble->$_ ) } @$columns )
            ###TODO: escape values
            . ");";

        $statement;
    };
}

1;
