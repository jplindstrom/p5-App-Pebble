
=head1 NAME

App::Pebble::PluginLoader - Base class for plugin loaders, e.g. Parsers.

=cut

package App::Pebble::PluginLoader;
use Moose;
use Method::Signatures;

use Class::Autouse;

sub package_prefix       { die( "Abstract\n" ) }
sub package_abbreviation { die( "Abstract\n" ) }

method load_plugins($class:) {
    my $package_prefix       = $class->package_prefix;
    my $package_abbreviation = $class->package_abbreviation;

    # Yeah, I know. Need autouse_recursive to return the loaded
    # packages instead of calling private sub.
    Class::Autouse->autouse_recursive( $package_prefix );
    my %short_long = map {
        my $short = $_;
        $short =~ s/^$package_prefix/$package_abbreviation/;
        
        $short => $_;
    } Class::Autouse::_child_classes( $package_prefix );

    for my $short ( keys %short_long ) {
        my $long = $short_long{ $short };
        no strict "refs";
        *{$short} = sub { $long };
    }

    return keys %short_long;
}

1;
