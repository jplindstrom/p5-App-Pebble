# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Modifier::Pipeline - IO::Pipeline based modifiers

=head1 DESCRIPTION

This modifier exports p* subs to provide the basic IO::Pipeline
plumbing.

=cut

package App::Pebble::Modifier::Pipeline;
use Moose;
extends "Exporter";
use Method::Signatures;
our @EXPORT = qw(
    p
    pmap
    pgrep
    ppool
    plimit
    pevery
    pn
);

use IO::Pipeline;

{
    no warnings "once";
    *p = *pmap;
}

sub plimit (&) {
    my ($limit_subref) = @_;
    my ($limit) = $limit_subref->();

    my $count = 0;
    return pgrep { $count++ < $limit; }
}

sub pevery (&) {
    my ($limit_subref) = @_;
    my ($every) = $limit_subref->() || 10;

    my $count = 0;
    return pgrep { ! ( $count++ % $every ) }
}

sub pn () {
    return pmap { "$_\n" };
}

1;
