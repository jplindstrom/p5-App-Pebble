# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::DBIS - DBIx::Simple source

=head1 DESCRIPTION

See L<DBIx::Simple> for an intro.

=cut

package App::Pebble::Plugin::Source::DBIS;
use Moose;

use Method::Signatures;

use App::Pebble::Config;
use DBIx::Simple;

=head1 METHODS

=head2 db( $datasource_or_connect_string, $username?, $password? ) : $dbix_simple_db

Connect to $datasource_or_connect_string and return a DBIx::Simple $db
object on which you can run queries.

$datasource_or_connect_string can be either a data source defined in
.pebble under the [datasource] heading, or a complete connect string.

=cut

my $connected_db;
method db($class: $datasource_or_connect_string?, $username?, $password? ) {
    my $docs = $datasource_or_connect_string or do {
        $connected_db or die( "S::DBIS->db: ->db() called without connecting to a database beforehand \n" );
        return $connected_db;
    };
    
    my $config = App::Pebble::Config->instance;
    my $datasource;
    my $connect;
    my $config_section = "datasource_$docs";
    if( $datasource = $config->{ $config_section } ) {
        defined ( $connect = $datasource->{connect} )
            or die( "S::DBIS->db: No 'connect' defined in the config section '[datasource_$docs].'\n" );
        $username ||= $datasource->{username};
        $password ||= $datasource->{password};
    }
    else {
        $docs =~ /^dbi:/i or die( "S::DBIS->db: [$config_section] is not defined in the config, and does not look like a DBI connect string.\n" );
        $connect = $docs;
    }

    $connected_db = DBIx::Simple->connect( $connect, $username, $password ) or die DBIx::Simple->error;
}

1;
