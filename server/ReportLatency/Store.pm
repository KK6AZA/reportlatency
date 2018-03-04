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

package ReportLatency::Store;

use strict;
use vars qw($VERSION %options);
use ReportLatency::utils;
use IO::String;
use URI::Escape;
use JSON;
use Data::Dumper;

$VERSION     = 0.1;
%options = ();

require ReportLatency::data;


sub new {
  my $class = shift;
  my %p = @_;

  my $self  = bless {}, $class;

  if (defined $p{dsn}) {
    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn) =
      DBI->parse_dsn($p{dsn});
    $self->{dialect} = $driver;
    $self->{dsn} = $p{dsn};
  } else {
    $self->{dsn} = latency_dsn();
    $self->{dialect} = latency_dialect();
  }

  $self->{dbh} = DBI->connect($self->{dsn}, '', '',
			      {AutoCommit => 0, RaiseError => 1})
    or die $DBI::errstr;

  return $self;
}

sub DESTROY {
  my $self = shift;
  $self->{dbh}->disconnect;
}

sub unix_timestamp {
  my ($self,$field) = @_;
  if ($self->{dialect} eq 'Pg') {
    return "extract(epoch from $field)";
  } else {
    return "strftime(\"%s\",$field)";
  }
}

sub db_to_unix {
  my ($self,$dbtime) = @_;
  my $sth = $self->{db_to_unix};
  if (! defined $sth) {
    $sth = $self->{dbh}->prepare("SELECT " .
				 $self->unix_timestamp('?') . ";");
    $self->{db_to_unix} = $sth;
  }
  $sth->execute($dbtime);
  my ($t) = $sth->fetchrow_array;
  $sth->finish;
  return $t;
}

sub db_timestamp {
  my ($self,$unix_time) = @_;
  my $dbh = $self->{dbh};
  if ($self->{dialect} eq 'Pg') {
    my $statement = "SELECT timestamp 'epoch' + '$unix_time seconds';";
    my ($t) = $dbh->selectrow_array($statement);
    return $t;

  } elsif ($self->{dialect} eq 'SQLite') {
    my $sth = $self->{db_timestamp_sth};
    if (! defined $sth) {
      $sth = $dbh->prepare("SELECT datetime(?,'unixepoch');") or die $!;
    }
    $sth->execute($unix_time);
    my ($t) = $sth->fetchrow_array;
    return $t;

  } elsif ($self->{dialect} eq 'MySQL') {
    my $sth = $self->{db_timestamp_sth};
    if (! defined $sth) {
      $sth = $dbh->prepare("SELECT from_unixtime(?);") or die $!;
    }
    $sth->execute($unix_time);
    my ($t) = $sth->fetchrow_array;
    return $t;
  } else {
    die $self->{dialect} . ' support unimplemented';
  }
}


sub register_option {
  my ($opt,$mask) = @_;
  $options{$opt} = $mask;
}


sub aggregate_remote_address {
  my ($self,$remote_addr,$forwarded_for) = @_;
  my $dbh = $self->{dbh};

  $self->{location_select} =
    $dbh->prepare('SELECT rdns,location from location where ip = ?')
      unless defined $self->{location_select};
  my $ip = $forwarded_for || $remote_addr;
  my $rc = $self->{location_select}->execute($ip);
  my $row = $self->{location_select}->fetchrow_hashref;
  $self->{location_select}->finish;
  if (defined $row) {
    return $row->{location} || $row->{rdns};
  } else {
    my $location = net_class_c($ip);
    my $rdns = reverse_dns($ip);
    if ($rdns) {
      my $subdomain = $rdns;
      $subdomain =~ s/^[^.]+\.//;
      if ($subdomain) {
	$location = $subdomain;
      }
    }
    $self->{location_insert} =
      $dbh->prepare("INSERT INTO LOCATION (timestamp,ip,rdns,location)" .
		    " VALUES(DATE('now'),?,?,?)")
      unless defined $self->{location_insert};
    $self->{location_insert}->execute($ip,$rdns,$location);
    $self->{location_insert}->finish;
    return $location;
  }
}

# process these form parameters and insert into same table columns
sub _thank_you {
  my $self = shift;
  print <<EOF;
Content-type: text/plain
Status: 200

Thank you for your report!

EOF
}

sub _error {
  my $self = shift;
  print <<EOF;
Content-type: text/plain
Status: 500

Error occured.

EOF
  print join("\n\n",@_);
}

sub option_bits {
  my ($self,$options) = @_;
  return undef unless defined $options;

  my $bits = 0;
  foreach my $opt (@{$options}) {
    if ($ReportLatency::Store::options{$opt}) {
      $bits |= $ReportLatency::Store::options{$opt};
    }
  }
  return $bits;
}

sub insert_stats {
  my ($self, $insert, $upload_id, $service, $name, $stats) = @_;

  $insert->execute($upload_id, $service, $name,
		   $stats->{'count'},
		   $stats->{'total'},
		   $stats->{'high'},
		   $stats->{'low'},
		   $stats->{'tabclosed'},
		   $stats->{'r200'},
		   $stats->{'r300'},
		   $stats->{'r400'},
		   $stats->{'r500'},
		   $stats->{'m100'},
		   $stats->{'m500'},
		   $stats->{'m1000'},
		   $stats->{'m2000'},
		   $stats->{'m4000'},
		   $stats->{'m10000'} );
}

sub add_navigation_request_stats {
  my ($self,$upload_id, $service, $name, $requeststats) = @_;

  $self->{insert_navigation_requests} =
    $self->{dbh}->prepare("INSERT INTO navigation_request " .
			  "(upload, service, name, count, total, high, low, " .
			  "tabclosed, response200, response300, " .
			  "response400, response500, " .
			  "m100, m500, m1000, m2000, m4000, m10000) " .
			  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);")
      unless defined $self->{insert_navigation_requests};

  $self->insert_stats($self->{insert_navigation_requests},
		      $upload_id, $service, $name, $requeststats);
}

sub add_update_request_stats {
  my ($self,$upload_id, $service, $name, $requeststats) = @_;

  $self->{insert_update_requests} =
    $self->{dbh}->prepare("INSERT INTO update_request " .
			  "(upload, service, name, count, total, high, low, " .
			  "tabclosed, response200, response300, " .
			  "response400, response500, " .
			  "m100, m500, m1000, m2000, m4000, m10000) " .
			  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);")
      unless defined $self->{insert_update_requests};

  $self->insert_stats($self->{insert_update_requests},
		      $upload_id, $service, $name, $requeststats);
}

sub add_navigation_stats {
  my ($self,$upload_id, $service, $name, $navstats) = @_;

  $self->{insert_navigations} =
    $self->{dbh}->prepare("INSERT INTO navigation " .
			  "(upload, service, name, count, total, high, low, " .
			  "tabclosed, response200, response300, " .
			 "response400, response500, " .
			  "m100, m500, m1000, m2000, m4000, m10000) " .
			  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);")
      unless defined $self->{insert_navigations};

  $self->insert_stats($self->{insert_navigations},
		      $upload_id, $service, $name, $navstats);
}


sub add_name_stats {
  my ($self,$upload_id, $service, $name, $namestats) = @_;

  if (defined $namestats->{'nreq'}) {
    $self->add_navigation_request_stats($upload_id, $service, $name,
					$namestats->{'nreq'});
  } 
  if (defined $namestats->{'ureq'}) {
    $self->add_update_request_stats($upload_id, $service, $name,
				    $namestats->{'ureq'});
  }
  if (defined $namestats->{'nav'}) {
    $self->add_navigation_stats($upload_id, $service, $name,
				$namestats->{'nav'});
  }
}


sub add_service_stats {
  my ($self,$upload_id, $service, $servicestats) = @_;

  foreach my $name (keys %{$servicestats}) {
    $self->add_name_stats($upload_id,$service, $name, $servicestats->{$name});
  }
}

sub new_upload {
  my ($self,$obj) = @_;

  $self->{upload_insert} =
    $self->{dbh}->prepare("INSERT INTO upload " .
		  "(collected_on,location,user_agent,tz,version,options)" .
		  " VALUES(?,?,?,?,?,?)")
      unless defined $self->{upload_insert};

  if (! defined $self->{hostname}) {
    $self->{hostname} = $ENV{SSL_SERVER_S_DN_CN} ||
      $ENV{SERVER_ADDR} || $ENV{SERVER_NAME} || $ENV{HTTP_HOST};
  }

  my $upload_sth =
    $self->{upload_insert}->execute($self->{hostname}, $obj->{location},
				    $obj->{user_agent}, $obj->{tz},
				    $obj->{version},
				    $obj->{options});
#  $upload_sth->finish();

  my ($lastval) = $self->{dbh}->selectrow_array("SELECT last_insert_rowid()");

  return $lastval;
}

sub parse_json {
  my ($self,$q) = @_;

  my $json = $q->param('POSTDATA');
  
  my $location =
    $self->aggregate_remote_address($ENV{'REMOTE_ADDR'},
				    $ENV{'HTTP_X_FORWARDED_FOR'});
  my $user_agent = aggregate_user_agent($ENV{'HTTP_USER_AGENT'});

  my $dbh = $self->{dbh};

  my $obj;
  $obj = JSON::decode_json $json;

  my $options = $self->option_bits($obj->{options});
  $obj->{options} = $options;
  $obj->{location} = $location;
  $obj->{user_agent} = $user_agent;

  my $upload_id = $self->new_upload($obj);

  foreach my $service (keys %{$obj->{services}}) {
    $self->add_service_stats($upload_id, $service,
			     $obj->{services}->{$service});
  }
  $dbh->commit or return $self->_error('commit',$dbh->errstr);
  $self->_thank_you();
}

sub post {
  my ($self,$q) = @_;

  if ($q->request_method() eq 'POST') {
    my $type = $q->content_type();
    if ($type eq 'application/json') {
      return $self->parse_json($q);
    } else {
      return $self->_error("inappropriate Content-Type ", $type);
    }
  } else {
    return $self->_error("inappropriate access method ", $q->request_method());
  }
}

sub service_nreq_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{service_nreq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'nr.count AS count,' .
      'nr.high AS high,' .
      'nr.low AS low,' .
      'nr.total AS total ' .
      'FROM navigation_request nr, upload u ' .
       "WHERE " .
       "u.timestamp > datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'nr.service = ? AND ' .
       'nr.upload = u.id AND ' .
       "nr.count IS NOT NULL AND nr.count != '' AND " .
       "nr.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{service_nreq_latencies_sth} = $sth;
  }

  return $sth;
}

sub service_ureq_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{service_ureq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'ur.count AS count,' .
      'ur.high AS high,' .
      'ur.low AS low,' .
      'ur.total AS total ' .
      'FROM update_request ur, upload u ' .
       "WHERE " .
       "u.timestamp > datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'ur.service = ? AND ' .
       'ur.upload = u.id AND ' .
       "ur.count IS NOT NULL AND ur.count != '' AND " .
       "ur.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{service_ureq_latencies_sth} = $sth;
  }

  return $sth;
}

sub tag_nav_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{tag_nav_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'n.count AS count,' .
      'n.high AS high,' .
      'n.low AS low,' .
      'n.total AS total ' .
      'FROM navigation n ' .
      'INNER JOIN upload u ON u.id=n.upload ' .
      'INNER JOIN tag ON n.service = tag.service ' .
       "WHERE u.timestamp >  datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'tag.tag = ? AND ' .
       "n.count IS NOT NULL AND n.count != '' AND " .
       "n.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{tag_nav_latencies_sth} = $sth;
  }

  return $sth;
}

sub tag_nreq_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{tag_nreq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'nr.count AS count,' .
      'nr.high AS high,' .
      'nr.low AS low,' .
      'nr.total AS total ' .
      'FROM navigation_request nr ' .
      'INNER JOIN upload u ON u.id=nr.upload ' .
      'INNER JOIN tag ON nr.service = tag.service ' .
       "WHERE u.timestamp >  datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'tag.tag = ? AND ' .
       "nr.count IS NOT NULL AND nr.count != '' AND " .
       "nr.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{tag_nreq_latencies_sth} = $sth;
  }

  return $sth;
}

sub tag_ureq_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{tag_ureq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'ur.count AS count,' .
      'ur.high AS high,' .
      'ur.low AS low,' .
      'ur.total AS total ' .
      'FROM update_request ur ' .
      'INNER JOIN upload u ON u.id=ur.upload ' .
      'INNER JOIN tag ON ur.service = tag.service ' .
       "WHERE u.timestamp >  datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'tag.tag = ? AND ' .
       "ur.count IS NOT NULL AND ur.count != '' AND " .
       "ur.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{tag_ureq_latencies_sth} = $sth;
  }

  return $sth;
}

sub service_nav_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{service_nav_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'n.count AS count,' .
      'n.high AS high,' .
      'n.low AS low,' .
      'n.total AS total ' .
      'FROM navigation n, upload u ' .
       "WHERE " .
       "u.timestamp > datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'n.service = ? AND ' .
       'n.upload = u.id AND ' .
       "n.count IS NOT NULL AND n.count != '' AND " .
       "n.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{service_nav_latencies_sth} = $sth;
  }

  return $sth;
}

sub location_nav_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{location_nav_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'n.count AS count,' .
      'n.high AS high,' .
      'n.low AS low,' .
      'n.total AS total ' .
      'FROM upload u, navigation n ' .
       "WHERE u.timestamp > datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'u.location = ? AND ' .
       'u.id=n.upload AND ' .
       "n.count IS NOT NULL AND n.count != '' AND " .
       "n.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{location_nav_latencies_sth} = $sth;
  }

  return $sth;
}

sub location_nreq_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{location_nreq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'nr.count AS count,' .
      'nr.high AS high,' .
      'nr.low AS low,' .
      'nr.total AS total ' .
      'FROM upload u, navigation_request nr ' .
       "WHERE u.timestamp > datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'u.location = ? AND ' .
       'u.id=nr.upload AND ' .
       "nr.count IS NOT NULL AND nr.count != '' AND " .
       "nr.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{location_nreq_latencies_sth} = $sth;
  }

  return $sth;
}

sub location_ureq_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{location_ureq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'ur.count AS count,' .
      'ur.high AS high,' .
      'ur.low AS low,' .
      'ur.total AS total ' .
      'FROM upload u, update_request ur ' .
       "WHERE u.timestamp > datetime('now',?) AND " .
       "u.timestamp <= datetime('now',?) AND " .
       'u.location = ? AND ' .
       'u.id=ur.upload AND ' .
       "ur.count IS NOT NULL AND ur.count != '' AND " .
       "ur.count>0;";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{location_ureq_latencies_sth} = $sth;
  }

  return $sth;
}

sub is_positive {
  my ($self,$field) = @_;
  my $expression = "$field IS NOT NULL";
  if ($self->{dialect} eq 'SQLite') {
    $expression .= " AND $field != ''";
  }
  $expression .= " AND $field>0";
  return $expression;
}

sub tag_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT count(distinct r.service) AS services,' .
		  'min(r.timestamp) AS min_timestamp,' .
                  'max(r.timestamp) AS max_timestamp,' .
		  $self->common_aggregate_fields() .
                  ' FROM report AS r ' .
                  'INNER JOIN tag ' .
                  'ON r.service = tag.service ' .
                  "WHERE r.timestamp >= datetime('now','-14 days') " .
		  'AND tag.tag = ?;')
      or die "prepare failed";
  return $sth;
}

sub tag_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT r.service AS service,' .
                  'count(distinct r.name) AS dependencies,' .
		  $self->common_aggregate_fields() .
                  ' FROM report AS r ' .
		  'INNER JOIN tag ' .
		  'ON r.service = tag.service ' .
                  'WHERE r.timestamp > ? AND r.timestamp <= ? ' .
		  'AND tag.tag = ? ' .
                  'GROUP BY r.service ' .
		  'ORDER BY r.service;')
      or die "prepare failed";
  return $sth;
}

sub common_aggregate_fields {
  my ($self) = @_;
  return 
    'sum(nreq_tabclosed) AS nreq_tabclosed,' .
    'sum(nreq_200) AS nreq_200,' .
    'sum(nreq_300) AS nreq_300,' .
    'sum(nreq_400) AS nreq_400,' .
    'sum(nreq_500) AS nreq_500,' .
    'sum(nreq_count) AS nreq_count,' .
    'sum(nreq_total)/sum(nreq_count) AS nreq_latency,' .
    'sum(nav_tabclosed) AS nav_tabclosed,' .
    'sum(nav_200) as nav_200,' .
    'sum(nav_300) as nav_300,' .
    'sum(nav_400) as nav_400,' .
    'sum(nav_500) as nav_500,' .
    'sum(nav_count) AS nav_count,' .
    'sum(nav_total)/sum(nav_count) AS nav_latency,' .
    'sum(ureq_200) AS ureq_200,' .
    'sum(ureq_300) AS ureq_300,' .
    'sum(ureq_400) AS ureq_400,' .
    'sum(ureq_500) AS ureq_500,' .
    'sum(ureq_count) AS ureq_count,' .
    'sum(ureq_total)/sum(ureq_count) AS ureq_latency';
}

sub service_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT service,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
		  "DATE('now') as date," .
		  $self->common_aggregate_fields() .
		  ' FROM report ' .
                  'WHERE service=? AND ' .
		  "timestamp >= DATETIME('now','-14 days');")
      or die "prepare failed";
  return $sth;
}

sub service_select_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT name,' .
		  $self->common_aggregate_fields() .
		  ' FROM report ' .
		  "WHERE service=? AND " .
		  "timestamp >= DATETIME('now','-14 days') " .
                  'GROUP BY name ' .
		  'ORDER BY name;')
      or die "prepare failed";
  return $sth;
}


sub service_location_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT location,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  'WHERE service=? AND ' .
		  "timestamp >= DATETIME('now','-14 days') " .
                  'GROUP BY location ' .
		  'ORDER BY location;')
      or die "prepare failed";
  return $sth;
}

sub summary_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare("SELECT 'total' AS tag," .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM upload, report3 ' .
                  "WHERE timestamp BETWEEN ? AND ? " .
		  "AND upload=id;" )
      or die "prepare failed";
  return $sth;
}


sub location_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT count(distinct service) AS services,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  "WHERE timestamp >= datetime('now','-14 days') " .
		  'AND location = ?;')
      or die "prepare failed";
  return $sth;
}


sub location_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT service AS service,' .
                  'count(distinct name) AS dependencies,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  'WHERE timestamp > ? AND timestamp <= ? ' .
		  'AND location = ? ' .
                  'GROUP BY service ' .
		  'ORDER BY service;')
      or die "prepare failed";
  return $sth;
}

sub create_current_temp_table {
  my ($self,$begin,$end,$arg) = @_;

  my $dbh = $self->{dbh};

  if (!defined $self->{current}) {
    my $sth =
      $dbh->prepare('CREATE TEMP TABLE current AS ' .
		    'SELECT *,' .
		    $self->unix_timestamp('timestamp') . ' AS utimestamp ' .
		    'FROM upload WHERE timestamp BETWEEN ? AND ?; ')
	or die "prepare failed";
    $self->{current} = $sth;
    benchmark_point("prepare CREATE TEMP TABLE current");
  }

  if (!(defined $self->{begin} && defined $self->{end} &&
	$self->{begin} eq $begin && $self->{end} eq $end)) {
    my $sth = $self->{current};
    if (defined $self->{current_rows}) {
      $dbh->do("DROP TABLE current;")
	or die "unable to drop current temp table";
    }
    $self->{current_rows} = $sth->execute($begin,$end) or die $sth->errstr;
    $self->{begin} = $begin;
    $self->{end} = $end;
    benchmark_point("CREATE TEMP TABLE current");
    $dbh->do('CREATE INDEX current_id ON current(id);');
    benchmark_point("CREATE INDEX current_id");
  }
}

sub create_service_report_temp_table {
  my ($self) = @_;
  my $dbh = $self->{dbh};

  if (!defined $self->{service_report}) {
  my $st = <<EOS;
CREATE TEMP TABLE service_report AS
SELECT service AS service,
       name AS name,
       location AS location,
       min(timestamp) AS min_timestamp,
       max(timestamp) AS max_timestamp,
       sum(count) AS nav_count,
       sum(total) AS nav_total,
       sum(tabclosed) AS nav_tabclosed,
       sum(response200) AS nav_200,
       sum(response300) AS nav_300,
       sum(response400) AS nav_400,
       sum(response500) AS nav_500,
       NULL AS nreq_count,
       NULL AS nreq_total,
       NULL AS nreq_tabclosed,
       NULL AS nreq_200,
       NULL AS nreq_300,
       NULL AS nreq_400,
       NULL AS nreq_500,
       NULL AS ureq_count,
       NULL AS ureq_total,
       NULL AS ureq_200,
       NULL AS ureq_300,
       NULL AS ureq_400,
       NULL AS ureq_500
FROM navigation, current
WHERE navigation.upload=current.id
GROUP BY service,name,location
UNION
SELECT service AS service,
       name AS name,
       location AS location,
       min(timestamp) AS min_timestamp,
       max(timestamp) AS max_timestamp,
       NULL AS nav_count,
       NULL AS nav_total,
       NULL AS nav_tabclosed,
       NULL AS nav_200,
       NULL AS nav_300,
       NULL AS nav_400,
       NULL AS nav_500,
       sum(count) AS nreq_count,
       sum(total) AS nreq_total,
       sum(tabclosed) AS nreq_tabclosed,
       sum(response200) AS nreq_200,
       sum(response300) AS nreq_300,
       sum(response400) AS nreq_400,
       sum(response500) AS nreq_500,
       NULL AS ureq_count,
       NULL AS ureq_total,
       NULL AS ureq_200,
       NULL AS ureq_300,
       NULL AS ureq_400,
       NULL AS ureq_500
FROM navigation_request, current
WHERE navigation_request.upload=current.id
GROUP BY service,location
UNION
SELECT service AS service,
       name AS name,
       location AS location,
        min(timestamp) AS min_timestamp,
        max(timestamp) AS max_timestamp,
	NULL AS nav_count,
        NULL AS nav_total,
	NULL AS nav_tabclosed,
	NULL AS nav_200,
	NULL AS nav_300,
	NULL AS nav_400,
	NULL AS nav_500,
	NULL AS nreq_count,
	NULL AS nreq_total,
	NULL AS nreq_tabclosed,
	NULL AS nreq_200,
	NULL AS nreq_300,
	NULL AS nreq_400,
	NULL AS nreq_500,
	sum(count) AS ureq_count,
	sum(total) AS ureq_total,
	sum(response200) AS ureq_200,
	sum(response300) AS ureq_300,
	sum(response400) AS ureq_400,
	sum(response500) AS ureq_500
FROM update_request, current
WHERE update_request.upload=current.id
GROUP BY service,name,location
;
EOS
    my $sth = $dbh->prepare( $st ) or die "prepare failed";
    $self->{service_report} = $sth->execute() or die $sth->errstr;

    benchmark_point("CREATE TEMP TABLE service_report");
  }
}

1;


=pod

==head1 NAME

ReportLatency::Store - Storage object for ReportLatency data

=head1 VERSION

version 0.1

=head1 SYNOPSIS

use LatencyReport::Store

$store = new LatencyReport::Store(
  dbh => $dbh
);

=head1 DESCRIPTION

LatencyReport::Store accepts reports and produces measurements for
table and spectrum generation.  The storage is in a database,
typically sqlite3 or syntactically compatible.

=head1 USAGE

=head2 Methods

=head3 Constructors

=over 4
=item * LatencyReport::Store->new(...)

=over 8

=item * dbh

The database handle for the sqlite3 or compatible database that should
be used for real storage by this object.  The schema must already be present.

=head3 Member functions

=over 4
=item * post(CGI)
=over 8
  Parse a CGI request object for latency report data and
  insert it into the database.

=head1 KNOWN BUGS

=head1 SUPPORT

=head1 SEE ALSO

=head1 AUTHOR

Drake Diedrich <dld@google.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright Google Inc.  All Rights Reserved.

This is free software, licensed under:

  The Apache 2.0 License

=cut
