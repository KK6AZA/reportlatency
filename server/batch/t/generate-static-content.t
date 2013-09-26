#!/usr/bin/perl -w
#
# Test generate-static-content.pl
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
use DBI;
use Test::More tests => 14;
use File::Temp qw(tempfile tempdir);

$ENV{'PATH'} = '/usr/bin';

BEGIN { use lib ".."; }

require_ok('./generate-static-content.pl');

my $dir = tempdir(CLEANUP => 1);
mkdir("$dir/data");
my $dbfile="$dir/data/backup.sqlite3";

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  open(my $sql,'<','../sql/sqlite3.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),'latency schema');
}

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile)
    or die $!;
  print $sqlite3 <<EOF;
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('service',3,666);
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('service',3,999);
UPDATE report SET timestamp=DATETIME('now','-1 days') WHERE navigation_total=999;
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('service',3,333);
UPDATE report SET timestamp=DATETIME('now','-2 days') WHERE navigation_total=333;
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('slow',1,6666);
UPDATE report SET timestamp=DATETIME('now','-1 days') WHERE navigation_total=6666;
EOF

  ok(close($sqlite3),"latency data added");
  sleep(1);
}

chdir("$dir");

main();

open(my $id,"-|","identify", "$dir/graphs/latency-spectrum.png") or die $!;
my $line = $id->getline;
like($line,
     qr/latency-spectrum\.png PNG \d+x\d+/,
     'PNG');

ok(unlink("$dir/graphs/latency-spectrum.png"),"unlink latency-spectrump.png");
ok(unlink("$dir/graphs/untagged.png"),"unlink untagged.png");
unlink($dbfile);
rmdir("$dir/data");
ok(unlink("$dir/graphs/service/service.png"),"rmdir service/service.png");
ok(unlink("$dir/graphs/location/.png"),"unlink null location png");
ok(rmdir("$dir/graphs/service"),"rmdir service/");
ok(rmdir("$dir/graphs/location"),"rmdir location/");
ok(rmdir("$dir/graphs"),"rmdir graphs/");
ok(unlink("$dir/service/service.html"),"unlink service.html");
ok(rmdir("$dir/service"),"unlink service/");
ok(rmdir($dir),"rmdir tmpdir");
