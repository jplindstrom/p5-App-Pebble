
=head1 NAME

App::Pebble::Renderer - Renderer plugins

=head1 DESCRIPTION

Renderers convert objects in the stream to output data, usually in the
stream but sometimes sideways.

Some renderers are lazy, i.e. they are able to convert a single object
to some output representation. Some are eager, i.e. they need to read
the whole dataset before they can output anything.

Renderers always go in the stream, never inside p {} or o {}.

=cut

package App::Pebble::Renderer;
use Moose;
extends "App::Pebble::PluginLoader";
use Method::Signatures;

use Exporter 'import';

sub package_prefix       { "App::Pebble::Plugin::Renderer" }
sub package_abbreviation { "R" }

our @EXPORT = __PACKAGE__->load_plugins();

1;
