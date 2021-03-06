#!/usr/bin/perl -w
#
# Test post.pl
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
use Test::More tests => 11;
use File::Temp qw/ tempfile tempdir /;
use IO::String;
use DBI;
use CGI::Util qw(escape unescape);

BEGIN { use lib '..'; }

use_ok('ReportLatency::Store');
require_ok( './post.pl' );


my $dir = tempdir(CLEANUP => 1);

mkdir("$dir/data");
mkdir("$dir/cgi-bin");
my $dbfile = "$dir/data/latency.sqlite3";
system("sqlite3 $dbfile < ../sql/sqlite3.sql");

chdir("$dir/cgi-bin");

$ENV{'HTTP_USER_AGENT'} = 'TestAgent';
$ENV{'REMOTE_ADDR'} = '1.2.3.4';
$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'CONTENT_TYPE'} = 'application/json';

my $in = new IO::String;
my $postcontent = <<EOF;
{
  "tz": "PST5PDT",
  "services": {
    "service_name": {
      "name": {
        "navigation": {
          "count": 1,
          "total": 1000
        }
      }
    }
  }
}
EOF

print $in $postcontent;
$ENV{'CONTENT_LENGTH'} = length($postcontent);

$in->setpos(0);
*OLD_STDIN = *STDIN;
*STDIN = $in;

my $out = new IO::String;
*OLD_STDOUT = *STDOUT;
select $out;
main();

select OLD_STDOUT;

*STDIN = *OLD_STDIN;

$out->setpos(0);
like($out->getline,qr/^Content-type:/, 'Content-type');
like($out->getline,qr/^Status: 2/,'2xx');

my $dbh;

$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",
		    {AutoCommit => 0, RaiseError => 1}, '')
  or die $dbh->errstr;

my $count_sth = $dbh->prepare("SELECT count(*) FROM upload");
$count_sth->execute();
my ($count) = $count_sth->fetchrow_array;
is($count, 1, '1 count');
$count_sth->finish;

my $upload_sth =
  $dbh->prepare("SELECT timestamp,location FROM upload WHERE user_agent=?");
$upload_sth->execute("Other");
my ($timestamp,$location) = $upload_sth->fetchrow_array;
like($timestamp,qr/^\d{4}-/,'timestamp');
is($location,'1.2.3.0','network address');

#my $report_sth =
#  $dbh->prepare("SELECT timestamp,remote_addr,name,final_name,navigation_count,navigation_total FROM report WHERE user_agent=?");
#is($name,'name','request name');
#is($service,'service_name','service name');
#is($nav_count,1,'navigation_count');
#is($nav_total,1000,'navigation_total');

ok(!$upload_sth->fetchrow_array,'  end of select');
$upload_sth->finish;

chdir();
ok(unlink($dbfile),"unlink $dbfile");
ok(rmdir("$dir/data"),"rmdir data/");
ok(rmdir("$dir/cgi-bin"),"rmdir cgi-bin/");
