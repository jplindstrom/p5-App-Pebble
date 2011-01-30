#!/usr/bin/env perl

use Google::Chart;

my $chart = Google::Chart->new(
  type => "Bar",
  size => "400x200",
  data => [ 90, 44, 20, 5, 5, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1 ],
  axis => [ { location => "x", labels => ["a", "b", "abc", "d", "/home/johan", "/home" ] } ],
);

print $chart->as_uri, "\n"; # or simply print $chart, "\n"

$chart->render_to_file( filename => 'filename.png' );
