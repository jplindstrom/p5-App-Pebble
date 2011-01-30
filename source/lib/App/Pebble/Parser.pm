
=head1 NAME

App::Pebble::Parser - Parser plugin loader

=head1 DESCRIPTION

Parsers convert data in the stream into objects.

Parser plugins have the prefix P::

Parsers always go in the stream, never inside p {} or o {}.

=cut

package App::Pebble::Parser;
use Moose;
extends "App::Pebble::PluginLoader";
use Method::Signatures;

use Exporter 'import';

sub package_prefix       { "App::Pebble::Plugin::Parser" }
sub package_abbreviation { "P" }

our @EXPORT = __PACKAGE__->load_plugins();

1;
