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
use Format::Human::Bytes;

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

sub pprogress (;&) {
    my ($subref) = @_;
    my %args = $subref ? $subref->() : ();
    my $message = $args{ message } || "";
    my $message_sub;
    if( ref( $message ) eq "CODE" ) {
        $message_sub = $message;
        $message = "";
    }

    ###TODO: obey --verbose

    my $count = 0;
    my $start_time = time();
    my $start_dt = DateTime->now();
    my $last_time = $start_time;
    return IO::Pipeline->from_code_map_all(
        sub {
            $_ && ref( $_ ) eq "IO::Pipeline::Control::BOF" and return $_;
            $_ && ref( $_ ) eq "IO::Pipeline::Control::EOF" and do {
                print STDERR "\n";
                return $_;
            };
            
            $count++;
            
            my $now = time();
            if( $now - $last_time >= 1 ) {
                my $now_dt = DateTime->now();
                my $duration = $now_dt - $start_dt;
                my $duration_text = join(
                    ":",
                    map { $duration->$_ } qw/ hours minutes seconds /
                );
                
                my $duration_s = $now - $start_time;
                my $objects_per_s = sprintf( "%0.1f", $count / ( $duration_s || 1 ) );
                
                my $count_k = Format::Human::Bytes::base10( $count );
                my $objects_per_s_k = Format::Human::Bytes::base10( $objects_per_s, 1 );
                s/B$// for ( $count_k, $objects_per_s_k );
                my $progress = sprintf( "%4s [$objects_per_s_k/s] $duration_text", $count_k );

                $message     and $progress .= " - $message";
                if( $message_sub && blessed( $_) && !$_->isa( "IO::Pipeline::Control" ) ) {
                    $progress .= " - " . $message_sub->();
                }
                
                local $\ = undef;
                print STDERR "\r$progress";
                
            }
            
            $last_time = $now;
            
            $_;
        }
    );
}

1;
