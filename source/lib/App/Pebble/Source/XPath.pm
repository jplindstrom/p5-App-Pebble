
=head1 NAME

App::Pebble::Source::XPath - XPath source, e.g. get + xpath matches

=cut

package App::Pebble::Source::XPath;
use Moose;
use MooseX::Method::Signatures;

use File::Slurp qw/ read_file /;
use XML::LibXML;
use XML::LibXML::XPathContext;

use App::Pebble::Source::Web;
use Data::Dumper;

method match($class: :$xml?, :$url?, :$file?, :$text?) {
    $xml || $url || $file or croak( "__FILE__->match takes either of 'xml', 'url', 'file'." );
    $text ||= {};

    my $content_type;
    $file and $xml = read_file( $file );
    $url and $xml = do {
        my $res = App::Pebble::Source::Web->get_response( $url );
        $content_type = $res->header( "Content-Type" ) || "";
        $res->content;
    };
    $xml or return ();

    my $dom = $class->parse_xml( $xml, $content_type );

    ###TODO: set namespace?

    my $xpc = XML::LibXML::XPathContext->new( $dom->documentElement )
       or warn( "Could not create XPathContext\n" ), return ();

    my %key_value;
    for my $key ( keys %$text ) {
        my $xpath = $text->{ $key };
        my @nodes = eval {
            map { $_->to_literal } $xpc->findnodes( $xpath )->get_nodelist;
        };
        $@ and die( "Invalid XPath ($xpath)\n" ), next;

        ###TODO: change this to obey type information to indicate
        ###scalar / list behaviour
        my $value = do {
          if( @nodes == 0 )    { undef      }
          elsif( @nodes == 1 ) { $nodes[0]  }
          else                 { [ @nodes ] }
        };
        $key_value{ $key } = $value;
     
    }

    return %key_value;
}

method parse_xml($class: $xml, $content_type?) {
    $content_type ||= $class->deduce_content_type( $xml );

    my $type_parser = {
        "application/xml"                => "parse_string",
        "application/xml; charset=utf-8" => "parse_string",
        "text/xml"                       => "parse_string",
    };
    my $parse_method = $type_parser->{ $content_type } || "parse_html_string";

    ###TODO: remove namespace?
    my $dom = eval {
        # Suppress warnings and STDERR output from LibXML
        local *STDERR = *STDOUT;
        local $SIG{__WARN__} = sub { };
        
        my $parser = XML::LibXML->new();
        $parser->recover(1);
        $parser->$parse_method($xml);
    } or warn( "Invalid ((($xml))), parsed as ($content_type)\n" ), return undef;

    return $dom;
}

method deduce_content_type($class: $xml) {
    $xml =~ m| \s* ( (?i) <?xml ) \b |smx and return "application/xml";
    return "";
}

1;
