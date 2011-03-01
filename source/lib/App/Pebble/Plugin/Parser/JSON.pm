# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Parser::JSON - Parse JSON input

=head1 DESCRIPTION

All lines with JSON definitions must be the same as the first one.

=cut

package App::Pebble::Plugin::Parser::JSON;
use Moose;
use Method::Signatures;

use JSON::XS;

use App::Pebble::Log qw/ $log /;
use App::Pebble::Modifier::Pipeline;
use Pebble::Object::Class;

my $_decoder = JSON::XS->new->convert_blessed; #->pretty;
method parse($class:) {
    ###TODO: $fields, to only capture a few of the parsed top level
    ###attributes

    my $line_count = 0;
    return pmap {
        my $line = $_;
        $line_count++;

        ###TODO: refactor, remove duplication with CSV
        $line =~ /^\s*#/ and return (); # Skip comment lines
        $line =~ /^\s*$/ and return (); # Skip empty lines (may contain whitespace)

        my $data;
        eval {
            $data = eval { $_decoder->decode( $line ) }
                or die( "Could not parse JSON line ($line_count) ($_): $@\n" );
            ref( $data ) eq "HASH"
                or die( "Bad data from JSON line ($line_count) ($_)\n" );
        };
        if( my $err = $@ ) {
            $log->error(  );
            return ();
        }

        return Pebble::Object::Class->new( %$data );
    };
}

1;
