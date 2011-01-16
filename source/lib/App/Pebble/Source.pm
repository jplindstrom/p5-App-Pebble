
=head1 NAME

App::Pebble::Source - Source plugins

=head1 DESCRIPTION

Sources bring data sideways into objects in the stream.

Sources always go inside o {}.

=cut

package App::Pebble::Source;
use Moose;
extends "App::Pebble::PluginLoader";
use Method::Signatures;

use Exporter 'import';

sub package_prefix       { "App::Pebble::Plugin::Source" }
sub package_abbreviation { "S" }

our @EXPORT = __PACKAGE__->load_plugins();

1;
