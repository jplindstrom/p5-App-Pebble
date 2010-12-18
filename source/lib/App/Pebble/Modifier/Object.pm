# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Modifier::Object - Pebble::Object modifiers

=head1 DESCRIPTION

This modifier exports o* subs to create and modify Pebble::Object
objects.

=cut

package App::Pebble;
use Moose;
use MooseX::Method::Signatures;
use Sub::Exporter -setup => { exports => [ qw(
  pmap
  pgrep
  ppool
  pn
  plimit
  onew
  omodify
  oadd
  oreplace
  okeep
  odelete
  omultiply
  osort
  ogroup
) ] };
    
use IO::Pipeline;
use List::MoreUtils qw/ each_arrayref /;

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

# leading 1 indicates numerical comparison
# leading - indicates a reverse sort order
# leading + indicates a normal sort order (default, but can be used for clarity)
#
# Examples:
# osort { "name" }
# osort {qw/ last_name first_name /}
# osort { "-name" }
# osort { "1size", "1-age_seconds" }
# osort { "1+size", "1-age_seconds", "name" }
sub osort (&) {
    my $subref = shift;
    my @sort_by = $subref->();

    my $sort_compare = join(
        "\n || \n",
        map {
            my $comparator = "cmp";
            s/^\d// and $comparator = "<=>";

            my $reverse = "";
            s/^-// and $reverse = " -1 * ";
            s/^\+//; # Clean up
            
            "($reverse( \$a->$_ $comparator \$b->$_ ))"
        } @sort_by
    );
    my $sort_sub = eval "sub { no warnings; $sort_compare }";

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

1;
