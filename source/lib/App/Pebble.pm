# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble - Unix like streams, but with objects instead of lines of text

=cut

package App::Pebble;
use Moose;

use IO::Pipeline;

use aliased "App::Pebble::Object" => "P";
use aliased "App::Pebble::Render" => "R";

#TODO: plugin system
use App::Pebble::Command::df;
use App::Pebble::Command::du;

no warnings "once";
*p = *pmap;

=head1 SYNOPSIS

The Unix idea of a stream of lines, on steroids.

Note: This is alpha, pure R&D at this stage; just trying out a good
way to do things.

=cut

sub pipeline {
    my $self = shift;
    my ($stages, $input_source, $input_source_fh) = @_;

    my @pipes = grep { $_ } @$stages;
    my $pipeline_perl = join( " |\n", @pipes );
#    print "((($pipeline_perl)))\n";

    eval $pipeline_perl;
    $@ and die;
  
}


=head1 AUTHOR

Johan Lindstrom, C<< <johanl at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-pebble at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Pebble>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Pebble


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Pebble>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Pebble>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Pebble>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Pebble/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010- Johan Lindstrom.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
