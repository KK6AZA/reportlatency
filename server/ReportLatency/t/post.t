#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm post()
#
# Copyright 2013,2014 Google Inc. All Rights Reserved.
# Copyright 2018 Drake Diedrich.  All Rights Reserved.
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
use warnings;
use DBI;
use CGI qw/ -utf8 /;
use IO::String;
use File::Temp qw(tempfile tempdir);
use Test::More tests => 22;

BEGIN { use lib '..'; }

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

my $store = new ReportLatency::Store(dsn => "dbi:SQLite:dbname=$dbfile");
my $dbh = $store->{dbh};

$ENV{'HTTP_USER_AGENT'} = 'TestAgent';
$ENV{'REMOTE_ADDR'} = '1.2.3.4';
$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'HTTP_USER_AGENT'} = $0;
$ENV{'CONTENT_TYPE'} = 'application/json';

my $poststring = <<EOF;
{"version":"1.1.0", "options":["default_as_org"], "tz":"PST", "services":{ "w3.org":{ "w3.org":{ "nreq":{ "m100":1, "m500":2, "m1000":1, "count":4, "total":461.09619140625}, "request":{ "count":1, "total":333.3}, "ureq":{ "m10000":1, "count":2, "total":64000}, "nav":{ "m1000":1, "count":1, "total":900}}}}}
EOF

my $postdata = new IO::String($poststring);
$postdata->setpos(0);

my $q = new CGI($postdata);

is($q->request_method(),'POST','request_method');
is($q->content_type(),'application/json','content-type');


ok($store->post($q),"post()");

$q->delete_all();

my ($count) = $dbh->selectrow_array("SELECT count(*) FROM upload");
is($count, 1, '1 upload');

($count) = $dbh->selectrow_array("SELECT count(*) FROM update_request");
is($count, 1, '1 update request entry');

($count) = $dbh->selectrow_array("SELECT count(*) FROM navigation_request");
is($count, 1, '1 navigation request entry');

($count) = $dbh->selectrow_array("SELECT count(*) FROM navigation");
is($count, 1, '1 navigation entry');


my ($sum) = $dbh->selectrow_array("SELECT sum(m100) FROM navigation_request");
is($sum, 1, "1 - 100ms nreq");

($sum) = $dbh->selectrow_array("SELECT sum(m500) FROM navigation_request");
is($sum, 2, "2 - 500ms nreq");

($sum) = $dbh->selectrow_array("SELECT sum(m1000) FROM navigation_request");
is($sum, 1, "1 - 1000ms nreq");

($sum) = $dbh->selectrow_array("SELECT sum(m10000) FROM update_request");
is($sum, 1, "1 - 10000ms ureq");

($sum) = $dbh->selectrow_array("SELECT sum(m1000) FROM navigation");
is($sum, 1, "1 - 1000ms nav");

my ($timestamp,$location) =
  $dbh->selectrow_array("SELECT timestamp,location " .
			"FROM upload");

like($timestamp,qr/^\d{4}-/,'timestamp');
is($location,'1.2.3.0','network address');

my ($service,$name) =
  $dbh->selectrow_array("SELECT service,name " .
			"FROM navigation");
is($name,'w3.org','w3.org navigation name');
is($service,'w3.org','w3.org navigation service');

($service,$name) =
  $dbh->selectrow_array("SELECT service,name " .
			"FROM update_request");
is($name,'w3.org','w3.org update request name');
is($service,'w3.org','w3.org update request service');

($service,$name) =
  $dbh->selectrow_array("SELECT service,name " .
			"FROM navigation_request");
is($name,'w3.org','w3.org navigation request name');
is($service,'w3.org','w3.org navigation request service');
