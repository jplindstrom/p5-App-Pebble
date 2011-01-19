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
    pprogress
);

use IO::Pipeline;
use DateTime;
use DateTime::Duration;

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

sub pprogress (&) {
    my ($limit_subref) = @_;
    #$limit_subref->();

    my $count = 0;
    my $start_time = time();
    my $start_dt = DateTime->now();
    my $last_time = $start_time;
    return pmap {
        $count++;

        my $now = time();
        if( $now - $last_time >= 1 ) {
            my $now_dt = DateTime->now();
            my $duration = $now_dt - $start_dt;
            my $duration_text = join( ":", map { $duration->$_ } qw/ hours minutes seconds / );

            my $duration_s = $now - $start_time;
            my $objects_per_s = sprintf( "%0.1f", $count / ( $duration_s || 1 ) );
            
            my $progress = "$count $duration_text [$objects_per_s/s]";

            local $\ = undef;
            print STDERR "\r$progress";

        }

        $last_time = $now;

        $_;
    }

}

1;
