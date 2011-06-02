
=head1 NAME

App::Pebble::Parser::OrgTable - Parse OrgTable input

=cut

package App::Pebble::Plugin::Parser::OrgTable;
use Moose;
use Method::Signatures;

use Carp;
use Text::CSV_XS;

use App::Pebble::Log qw/ $log /;
use App::Pebble::Modifier::Pipeline;
use Pebble::Object::Class;

###TODO: refactor this copy-paste from Parser::CSV

method parse($class: :$csv_args, :$fields, :$has_header = 0) {
    $fields || $has_header or croak( "P::OrgTable->parse requires either a list of 'fields' or 'has_header' to be specified" );

    $csv_args->{quote_char} ||= q/"/;
    $csv_args->{sep_char} ||= q/|/;
    my $csv = Text::CSV_XS->new( $csv_args );

    my $line_count = 0;
    my $has_seen_header = 0;
    return pmap {
      my $line = $_;
      # Remove leading and trailing "separators"
      $line =~ s/^\|\s+//;
      $line =~ s/\s+\|$//;

      $line_count++;

      $line =~ /^\s*#/ and return (); # Skip comment lines
      $line =~ /^\s*$/ and return (); # Skip empty lines (may contain whitespace)

      $csv->parse($line) or do {
        $log->error( "Could not parse OrgTable line ($line_count) ($line)" );
        return ();
      };
      my @field_values  = $csv->fields;

      # Remove whitespace
      for ( @field_values ) {
        s/^\s+//;
        s/\s+$//;
      }

      if( ( !$has_seen_header ) && $has_header ) {
          $fields ||= [ map {
              s/^\s+//;    # Remove leading whitespace
              s/\s+$//;    # Remove trailing whitespace
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
