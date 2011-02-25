# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Modifier::Object - Pebble::Object modifiers

=head1 DESCRIPTION

This modifier exports o* subs to create and modify Pebble::Object
objects.

=cut

package App::Pebble::Modifier::Object;
use Moose;
extends "Exporter";

our @EXPORT = qw(
    onew
    omodify
    oadd
    oreplace
    okeep
    odelete
    omultiply
    ogrep
    osort
    ogroup_count
    ogroup
    otracer_bullet
    o
);

use Method::Signatures;
use List::MoreUtils qw/ each_arrayref uniq /;
use Statistics::Descriptive;

use App::Pebble::Log qw/ $log /;

use aliased "Pebble::Object::Class" => "O";
use App::Pebble::Modifier::Pipeline;


sub o (&) {
    my $subref = shift;
    my $previous_object;
    return pmap {
        $subref->($previous_object);
        $previous_object = $_;
    };
}

# TODO? Refactor these, or keep inlined for clarity and perf?

sub onew (&) {
    my $subref = shift;
    return pmap {
        my %arg  = $subref->();
        O->new( %arg );
    };
}

sub omodify (&) {
    my $subref = shift;
    return pmap {
        my %arg  = $subref->();
        O->modify( %arg );
    };
}

sub oadd (&) {
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

sub okeep (&) {
    my $subref = shift;
    return pmap {
        my @args  = $subref->();
        O->modify( -keep => [ @args ] );
    };
}

sub odelete (&) {
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

sub ogrep (&) {
    my $subref = shift;
    my %field_condition = $subref->();

    ###TODO: validate that for my $field ( keys %field_condition ) { are attributes

    my $condition_sub = {
        numerical => sub { _is_numerical( shift ) },
        defined   => sub { defined( shift ) },
        true      => sub { !! shift },
    };

    return pgrep {
        for my $field ( keys %field_condition ) {
            my $condition = $field_condition{ $field };

            my $sub;
            ref( $condition ) eq "CODE" and $sub = $condition;
            $sub ||= $condition_sub->{ $condition }
                or die( "Unknown condition ($condition) in ogrep():\n"
                      . "Allowed conditions are: "
                      . join( ", ", map { "'$_'" } keys %$condition_sub )
                      . "\n" );
            $sub->( $_->$field ) or return 0;
        }

        return 1;
    };
}

# TOOD: Find non-naive solution
sub _is_numerical {
    my ($value) = @_;
    defined $value or return 0;
    return $value =~ /^-?[\d.]+$/;    
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
            defined $by_key or $by_key = "";
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

# Example: ogroup { query => { $attribute => "$grouped_attribute->$group_function" } }
# Example: ogroup { query => { mean_duration => { duration => "mean" }, count => { query => "count" } } }
# Example: ogroup { query => { _duration => [ mean", "count" ] } }
sub ogroup (&) {
    my $subref = shift;
    my ($by, $into_attribute_grouped_attribute_function) = $subref->();

    my @grouped_attributes =
        sort uniq(
          map { keys %$_ }
          values %$into_attribute_grouped_attribute_function,
        );
    ###TODO: error checking that these exist
    ###TODO: error checking that the grouping functions exist

    my @into_attributes = sort uniq( keys %$into_attribute_grouped_attribute_function );
    ###TODO: error checking that these exist

    my %by_object;
    my $by_value_statistics = {};
    return ppool(
        sub {
            my $by_value = $_->{ $by };
            $by_object{ $by_value } ||= $_;

            for my $grouped_attribute ( @grouped_attributes ) {
                my $statistics = $by_value_statistics->{ $by_value }->{ $grouped_attribute }
                    ||= Statistics::Descriptive::Full->new;
                my $value = $_->{ $grouped_attribute };
                my $numeric_value = $value; ### undef?
                $numeric_value =~ /^-?[\d.]+$/ or $numeric_value = 0;
                $statistics->add_data( $numeric_value );
            }
            return ();
        },
        sub {
            my @grouped =
#               sort { $a->$into <=> $b->$into }
                map {
                    my $o = $_;
                    my $by_value = $o->{ $by };

                    my $new_attribute_value = {};
                    for my $into_attribute ( @into_attributes ) {
                        for my $grouped_attribute ( keys %{ $into_attribute_grouped_attribute_function->{ $into_attribute } } ) {
                            my $function = $into_attribute_grouped_attribute_function->{ $into_attribute }->{ $grouped_attribute };
                            my $statistics = $by_value_statistics->{ $by_value }->{ $grouped_attribute };
                            my $value = $statistics->$function; ###TODO: validate $function
                            $value ne int( $value ) and $value = sprintf( "%0.3f", $value );
                            $new_attribute_value->{ $into_attribute } = $value;
                        }
                    }

                    O->modify( -add => $new_attribute_value );
                }
              values %by_object;
            return @grouped;
        }
      );
}

sub otracer_bullet (&) {
    my $subref = shift;
    my $message = $subref->();
    my $count = 0;
    return  o {
        $count++;
        ###TODO: log, or debug level
        $log->warning( "$message - $count" );
    };
}

1;
