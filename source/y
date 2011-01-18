  p { S::Web->get( "http://www.imdb.com/find?s=all&q=$_" ) }
  | P->match( regex => qr|Popular\sTitles .+? <a\s+href="/title/(\w+)/"|xsm, has => "imdb_id" )
  | oadd { imdb_url => "http://www.imdb.com/title/" . $_->imdb_id }
  | oadd { html => S::Web->get( $_->imdb_url ) }
  | p {
      my @actors;
      my $html = $_->html;
      while( $html =~ m|<td class="name">\s+<a\s+href="/name/(\w+)/">(.+?)</a>\s+</td>|gsm ) {
          push @actors => O->new( id => $1, name => $2 );
      }

      @actors;
  }
