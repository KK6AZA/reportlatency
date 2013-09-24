#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm
#
# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use CGI;
use DBI;
use File::Temp qw(tempfile tempdir);
use Test::More tests => 6;
use HTML::Tidy;

BEGIN {
  use lib '..';
}

use_ok( 'ReportLatency::Store' );

my $dir = tempdir(CLEANUP => 1);
my $dbfile = "$dir/latency.sqlite3";
{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  open(my $sql,'<','../sql/sqlite3.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),'latency schema');
}

my $dbh;
$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",
		       {AutoCommit => 0}, '')
  or die $dbh->errstr;

my $store = new ReportLatency::Store(dbh => $dbh);

isa_ok($store, 'ReportLatency::Store');

is($store->{dbh}, $dbh, "dbh");

my $tidy = new HTML::Tidy;
my $summary_html = $store->summary_html();

ok($dbh->do(q{
  INSERT INTO report(timestamp,name,final_name,request_count,request_total) VALUES(9999,'google.com','google.com',1,1000);
}), 'INSERT google.com report');

is($tidy->parse('summary_html',$summary_html), 1, 'summary.html');
for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();
