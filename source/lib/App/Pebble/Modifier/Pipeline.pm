# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Modifier::Pipeline - IO::Pipeline based modifiers

=head1 DESCRIPTION

This modifier exports p* subs to provide the basic IO::Pipeline
plumbing.

=cut

package App::Pebble::Modifier::Pipeline;
use Moose;
use MooseX::Method::Signatures;
use Sub::Exporter -setup => { exports => [ qw(
  pmap
  pgrep
  ppool
  pn
  plimit
) ] };
    
use IO::Pipeline;

no warnings "once";
*p = *pmap;

sub plimit (&) {
    my ($limit_subref) = @_;
    my ($limit) = $limit_subref->();
    
    my $count = 0;
    return pgrep { $count++ < $limit; }
}

sub pn () {
    return pmap { "$_\n" };
}

1;
