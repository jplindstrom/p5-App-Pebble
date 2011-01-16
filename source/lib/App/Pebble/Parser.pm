
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

sub package_prefix       { "App::Pebble::Plugin::Parser" }
sub package_abbreviation { "P" }

method load_plugins($class:) {
    my $package_prefix       = $class->package_prefix;
    my $package_abbreviation = $class->package_abbreviation;

    # Yeah, I know. Need autouse_recursive to return the loaded
    # packages.
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

    our @EXPORT = ( keys %short_long );
}

BEGIN { __PACKAGE__->load_plugins() }

1;
