
=head1 NAME

App::Pebble::Parser::CSV - Parse CSV input

=cut

package App::Pebble::Plugin::Parser::CSV;
use Moose;
use Method::Signatures;

use Text::CSV_XS;

use App::Pebble::Modifier::Pipeline;
use Pebble::Object::Class;

method parse($class: :$csv_args, :$fields, :$parse_fields = 0) {
    $fields || $parse_fields or croak( "P::CSV requires either a list of 'fields' or 'parse_fields' to be specified");
    $fields ||= [];

    $csv_args->{quote_char} ||= q/"/;
    my $csv = Text::CSV_XS->new( $csv_args );

    my $line_count = 0;
    my $seen_field_names = 0;
    return pmap {
      my $line = $_;
      $line_count++;

      $line =~ /^\s*#/ and return (); # Skip comment lines
      $line =~ /^\s*$/ and return (); # Skip empty lines (may contain whitespace)

      $csv->parse($_) or do {
        warn( "Could not parse CSV line ($line_count) ($_)\n" );
        return ();
      };
      my @field_values  = $csv->fields;

      if( ( !$seen_field_names ) && $parse_fields ) {
          $fields = [ map {
              s/^\s+//;    # Remove leading whitespace
              s/s+$//;     # Remove trailing whitespace
              s/\W+/_/gsm; # Replace invalid variable name chars with _
              $_,
          } @field_values ];
          $seen_field_names = 1;
      }

      my %field_value = map { $_ => shift( @field_values ) } @$fields;

      return Pebble::Object::Class->new( %field_value );
    };
}


1;
