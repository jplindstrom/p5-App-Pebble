
=head1 NAME

App::Pebble::Parser::CSV - Parse CSV input

=cut

package App::Pebble::Plugin::Parser::CSV;
use Moose;
use Method::Signatures;

use Text::CSV_XS;

use App::Pebble::Log qw/ $log /;
use App::Pebble::Modifier::Pipeline;
use Pebble::Object::Class;

method parse($class: :$csv_args, :$fields, :$has_header = 0) {
    $fields || $has_header or croak( "P::CSV->parse requires either a list of 'fields' or 'has_header' to be specified" );

    $csv_args->{quote_char} ||= q/"/;
    my $csv = Text::CSV_XS->new( $csv_args );

    my $line_count = 0;
    my $has_seen_header = 0;
    return pmap {
      my $line = $_;
      $line_count++;

      $line =~ /^\s*#/ and return (); # Skip comment lines
      $line =~ /^\s*$/ and return (); # Skip empty lines (may contain whitespace)

      $csv->parse($_) or do {
        $log->error( "Could not parse CSV line ($line_count) ($_)" );
        return ();
      };
      my @field_values  = $csv->fields;

      if( ( !$has_seen_header ) && $has_header ) {
          $fields ||= [ map {
              s/^\s+//;    # Remove leading whitespace
              s/s+$//;     # Remove trailing whitespace
              s/\W+/_/gsm; # Replace invalid variable name chars with _
              $_,
          } @field_values ];
          $has_seen_header = 1;
          return ();
      }

      my %field_value = map { $_ => shift( @field_values ) } @$fields;

      return Pebble::Object::Class->new( %field_value );
    };
}


1;
