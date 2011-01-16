
=head1 NAME

App::Pebble::Parser - Parser plugins

=head1 DESCRIPTION

Parsers convert data in the stream into objects.

Parsers always go in the stream, never inside p {} or o {}.

=cut

package App::Pebble::Parser;
use Moose;
use Method::Signatures;

use Exporter 'import';
use Class::Autouse;

###TODO: load plugins, alias them
BEGIN {
    my $package_prefix = "App::Pebble::Plugin::Parser";
    Class::Autouse->autouse_recursive( $package_prefix );
    my %short_long = map {
        my $short = $_;
        $short =~ s/^$package_prefix/P/;
        
        $short => $_;
    }
    Class::Autouse::_child_classes( $package_prefix );

    for my $short ( keys %short_long ) {
        my $long = $short_long{ $short };
        no strict "refs";
        *{$short} = sub { $long };
    }

    our @EXPORT = ( keys %short_long );
}

1;
