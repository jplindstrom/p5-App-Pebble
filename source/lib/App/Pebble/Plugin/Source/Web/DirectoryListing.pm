# -*- mode: cperl; cperl-indent-level: 4; -*-

=head1 NAME

App::Pebble::Plugin::Source::Web::DirectoryListing - Extract links
from a HTTP directory listing

=cut

package App::Pebble::Plugin::Source::Web::DirectoryListing;
use Moose;
use Method::Signatures;

use URI;

use App::Pebble::Modifier::Object;
use App::Pebble::Modifier::Pipeline;


method oadd_links($class: $listing_url_attribute, :$link_attribute?, :$link_text_attribute?) {
    $link_attribute      ||= "link_url";
    $link_text_attribute ||= "link_text";

    #TODO: validate $url_attribute

    return oadd {
        S::XPath->match(
            xml           => S::Web->get( $_->$listing_url_attribute ),
            text          => {
                $link_attribute      => q|//a/@href|,
                $link_text_attribute => q|//a/text()|,
            }
        )
    }
    | omultiply { $link_attribute, $link_text_attribute }
    | pgrep { $_->$link_attribute !~ /\W/ }  # Filter out junk links; only works for this page, not a general solution in _any_ way
    | o { $_->$link_attribute( URI->new_abs( $_->$link_attribute, $_->listing_url ) ) }
    | odelete { $listing_url_attribute }
    ;
}

1;
