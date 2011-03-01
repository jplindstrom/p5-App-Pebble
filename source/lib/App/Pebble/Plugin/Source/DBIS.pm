# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::DBIS - DBIx::Simple source

=head1 DESCRIPTION

See L<DBIx::Simple> for an intro.

=cut

package App::Pebble::Plugin::Source::DBIS;
use Moose;

use Method::Signatures;

use DBIx::Simple;

=head1 METHODS

=head2 db( $datasource_or_connect_string, $username?, $password? ) : $dbix_simple_db

Connect to $datasource_or_connect_string and return a DBIx::Simple $db
object on which you can run queries.

$datasource_or_connect_string can be either a data source defined in
.pebble under the [datasource] heading, or a complete connect string.

=cut

method db($class: $datasource_or_connect_string, $username?, $password? ) {
    
}

1;
