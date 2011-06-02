
=head1 NAME

App::Pebble::Plugin::Parser::FilenameElm - Parse *.elm (e.g. saved
Thunderbird emails) into dates and contents

=cut

package App::Pebble::Plugin::Parser::FilenameElm;
use Moose;
use Method::Signatures;

use App::Pebble::Modifier::Pipeline;
use App::Pebble::Modifier::Object;
use App::Pebble::Plugin::Parser::Regex;

method parse($class:) {

    # Some mail subject line - MySQL User <mysql@your.database.server1.com> - 2011-03-11 1300.eml
    return
        App::Pebble::Plugin::Parser::Regex->match(
          has => {
            file => qr/(.+)/,
            date => qr/> - ([\d -]+)\.eml/,
          },
        )
        | pgrep { defined $_->date }
          # 2010-12-06 1823
        | o { $_->date( substr( $_->date, 0, 15) ) }
        | S::DateTime->oconvert_parse( "date" )
#        | osort { "date" }
#        | oadd { body => scalar S::File->slurp( $_->file ) };
}

1;
