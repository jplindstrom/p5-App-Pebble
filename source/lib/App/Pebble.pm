# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble - Unix like streams, but with objects instead of lines of text

=head1 SYNOPSIS

=head2 Work with lines of text

  # pgrep, pn: Filter out POD lines, add a \n
  cat lib/App/Pebble.pm | pebble 'pgrep { /^=/ } | pn'
  =head1 NAME
  =head1 SYNOPSIS
  =head1 DESCRIPTION
  ...

  # The same, limit output to 2 lines
  cat lib/App/Pebble.pm | p 'pgrep { /^=head/ } | plimit 2 | pn'
  =head1 NAME
  =head1 SYNOPSIS

=head2 Work with objects

  # P->match: Parse matching lines into objects with named attributes.
  # The default output format is one-line JSON.
  cat lib/App/Pebble.pm | \
  p 'P->match({ regex => qr/^=head(\d+)\s+(.+)/, has => ["level", "text"] })'
  {"level":"1","text":"NAME"}
  {"level":"1","text":"SYNOPSIS"}
  {"level":"1","text":"DESCRIPTION"}
  ...

  ###TODO: split

  ###TODO: parsers

  # R->table: Do the same, but provide a Renderer (table) as the final stage
  cat lib/App/Pebble.pm | \
  p 'P->match({ regex => qr/^=head(\d+)\s+(.+)/, has => ["level", "text"] }) | R->table'
  .-------------------------------.
  | level | text                  |
  +-------+-----------------------+
  |     1 | NAME                  |
  |     1 | SYNOPSIS              |
  |     1 | DESCRIPTION           |
  ...
  '-------+-----------------------'

  # --out=CSV: Do the same, but provide a CSV renderer on the command line,
  # not as the final stage.
  # You can install more renderers, and write your own.
  cat lib/App/Pebble.pm | \
  p --out=CSV 'P->match({ regex => qr/^=head(\d+)\s+(.+)/, has => ["level", "text"] })'
  level,text
  1,NAME
  1,SYNOPSIS
  1,DESCRIPTION


=head2 Filtering objects

  # pgrep: Filter out headings with too long text
  cat lib/App/Pebble.pm | \
  p --out=table 'P->match({ regex => qr/^=head(\d+)\s+(.+)/, has => ["level", "text"] })
  | pgrep { length( $_->text) < 5 }'
  .--------------.
  | level | text |
  +-------+------+
  |     1 | NAME |
  |     1 | BUGS |
  '-------+------'

=head2 Transforming objects

  # p / pmap: Shorten the text value to at most 5 chars
  # "pmap" is so commonly used it's aliased to "p" for convenience.
  # Note that you still want the object itself to be passed along in the stream,
  # so you need to end the block with $_;
  cat lib/App/Pebble.pm | p --out=table 'P->match({ regex => qr/^=head(\d+)\s+(.+)/, has => ["level", "text"] }) | p { $_->text( substr($_->text, 0, 5 )); $_ }'
  .---------------.
  | level | text  |
  +-------+-------+
  |     1 | NAME  |
  |     1 | SYNOP |
  |     1 | DESCR |
  ...

###TODO: local variables

=head2 Work with predefined commands

  # --cmd=df: Run "df -k" and parse the output
  p --cmd=df --out=table 'plimit 2'
  .--------------------------------------------------------------------------.
  | available | blocks    | capacity | filesystem   | mounted_on | used      |
  +-----------+-----------+----------+--------------+------------+-----------+
  |  21856800 | 976101344 |       98 | /dev/disk0s2 | /          | 953732544 |
  |         0 |       216 |      100 | devfs        | /dev       |       216 |
  '-----------+-----------+----------+--------------+------------+-----------'

=cut

package App::Pebble;
use Moose;
use MooseX::ClassAttribute;
use MooseX::Method::Signatures;

use IO::Pipeline;
use List::MoreUtils qw/ each_arrayref /;

use aliased "App::Pebble::Parse" => "P";
use aliased "App::Pebble::Render" => "R";
use aliased "Pebble::Object::Class" => "O";
use aliased "App::Pebble::Source" => "S";

#TODO: plugin system
use App::Pebble::Command::df;
use App::Pebble::Command::du;

no warnings "once";
*p = *pmap;

=head1 DESCRIPTION

The Unix idea of a stream of lines, on steroids.

Note: This is alpha, pure R&D at this stage; just trying out a good
way to do things.

=cut


=head1 CLASS ATTRIBUTES

=head2 cache[ Cache::Cache | undef ]

Optional cache object, used for e.g. web requests.

=cut

class_has cache => ( is => "rw" );


=head1 METHODS

=cut

method pipeline( $stages, $input_source, $input_source_fh ) {
    @$stages = grep { $_ } @$stages;
    my $pipeline_perl = join( " |\n", @$stages );
warn "((($pipeline_perl)))\n";

    eval $pipeline_perl;
    $@ and die;

}

sub plimit (&) {
    my ($limit_subref) = @_;
    my ($limit) = $limit_subref->();
    
    my $count = 0;
    return pgrep { $count++ < $limit; }
}

sub pn () {
    return pmap { "$_\n" };
}

# TODO? Refactor these, or keep inlined for clarity and perf?

sub onew     (&) {
    my $subref = shift;
    return pmap {
        my %arg  = $subref->();
        O->new( %arg );
    };
}

sub omodify     (&) {
    my $subref = shift;
    return pmap {
        my %arg  = $subref->();
        O->modify( %arg );
    };
}
sub oadd     (&) {
    my $subref = shift;
    return pmap {
        my %arg  = $subref->();
        O->modify( -add => { %arg } )
    };
}
sub oreplace (&) {
    my $subref = shift;
    return pmap {
        my %arg  = $subref->();
        O->modify( -replace => { %arg } );
    };
}
sub okeep    (&) {
    my $subref = shift;
    return pmap {
        my @args  = $subref->();
        O->modify( -keep => [ @args ] );
    };
}
sub odelete  (&) {
    my $subref = shift;
    return pmap {
        my @args = $subref->();
        O->modify( -delete => [ @args ] );
    };
}

sub omultiply (&) {
    my $subref = shift;
    my $multiply_by = [ $subref->() ];
    return pmap {
        my $object = $_;

        ###TODO: ensure the value is an arrayref, might be a scalar
        my $by_values = each_arrayref( map { $object->$_ } @$multiply_by );
        
        my @sum;
        while ( my @vars = $by_values->() ) {
            my $new_object = O->clone( $object );
            for my $attribute ( @$multiply_by ) {
                $new_object->$attribute( shift( @vars ) );
            }

            push( @sum, $new_object );
        }

        return @sum;
    };
}

sub osort (&) {
    my $subref = shift;
    my @sort_by = $subref->();

    my $sort_compare = join( " || ", grep { "( \$a->$_ cmp \$b->$_ )" } @sort_by );
    my $sort_sub = eval "sub { $sort_compare }";

    my @objects;
    return ppool(
        sub {
            push @objects => $_;
            return ();
        },
        sub { @objects = sort $sort_sub @objects },
    );
}

# Example: ogroup_count { query => query_count }
sub ogroup_count (&) {
    my $subref = shift;
    my ($by, $into) = $subref->();
    my %by_object;
    my %by_count;
    return ppool(
        sub {
            my $by_key = $_->{ $by };
            $by_object{ $by_key } ||= $_;
            $by_count{ $by_key }++;
            return ();
        },
        sub {
            my @grouped = 
                sort { $a->$into <=> $b->$into }
                map { O->modify( -add => { $into => $by_count{ $_->$by } } ) }
                values %by_object;
            return @grouped;
        }
      );
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
