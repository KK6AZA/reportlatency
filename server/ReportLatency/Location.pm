# Copyright 2014 Google Inc. All Rights Reserved.
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

package ReportLatency::Location;
use ReportLatency::utils;
use ReportLatency::Base;
use Carp qw( croak confess );
@ISA = ("ReportLatency::Base");

use strict;
use vars qw($VERSION);

$VERSION     = 0.1;

sub new {
  my $class = shift;
  my $self  = bless {}, $class;
  $self->{store} = shift;
  my $begin = $self->{begin} = shift;
  my $end = $self->{end} = shift;
  $self->{location} = shift;

  $self->{store}->create_current_temp_table($begin,$end);

  return $self;
}


sub title {
  my $self=shift;
  return $self->{location};
}

sub name_title {  return "Service"; }
sub count_title { return "Depend"; }
sub meta_count_title { return "Services"; }

sub tag_url {
  my ($self, $view, $name) = @_;
  return $view->service_url_from_location($name);
}


sub execute {
  my ($self,$sth) = @_;
  my $rv = $sth->execute($self->{location});
  return $rv if $rv;
  cluck $sth->errstr;
  undef;
}

sub latency_select {
  my ($self,$latency) = @_;
  my $store = $self->{store};
  my $ts = $store->unix_timestamp('u.timestamp');
  my $positive = $store->is_positive('n.count');
  return <<EOS;
SELECT 
  $ts AS timestamp,
  n.count AS count,
  n.high AS high,
  n.low AS low,
  n.total AS total 
FROM current u, $latency n
WHERE u.location=? AND n.upload=u.id AND $positive;
EOS
}

sub selector {
  my ($self,$latency) = @_;
  return <<EOS;
FROM current AS u, $latency AS n
WHERE u.location=? AND n.upload=u.id
EOS
}

sub latency_histogram {
  my ($self,$latency) = @_;
  my $selector = $self->selector($latency) . ' AND amount>0';
  return <<EOS;
SELECT utimestamp AS timestamp,'closed' AS measure,tabclosed AS amount 
$selector
UNION
SELECT utimestamp AS timestamp,'100ms' AS measure,m100 AS amount 
$selector
UNION
SELECT utimestamp AS timestamp,'500ms' AS measure,m500 AS amount 
$selector
UNION
SELECT utimestamp AS timestamp,'1s' AS measure,m1000 AS amount 
$selector
UNION
SELECT utimestamp AS timestamp,'2s' AS measure,m2000 AS amount 
$selector
UNION
SELECT utimestamp AS timestamp,'4s' AS measure,m4000 AS amount 
$selector
UNION
SELECT utimestamp AS timestamp, '10s' AS measure,m10000 AS amount 
$selector
UNION
SELECT utimestamp AS timestamp,'long' AS measure,
COALESCE(count,0)-COALESCE(m100,0)-COALESCE(m500,0)-COALESCE(m1000,0)-COALESCE(m2000,0)-COALESCE(m4000,0)-COALESCE(m10000,0)-COALESCE(tabclosed,0) AS amount 
$selector
;
EOS
}

sub nav_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('navigation'))
   or die $!;
  my $tag = $self->{location};
  $sth->execute($tag,$tag,$tag,$tag,$tag,$tag,$tag,$tag);
  return $sth;
}

sub nreq_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('navigation_request') )
    or die $!;
  my $tag = $self->{location};
  $sth->execute($tag,$tag,$tag,$tag,$tag,$tag,$tag,$tag);
  return $sth;
}

sub ureq_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('update_request') )
    or die $!;
  my $tag = $self->{location};
  $sth->execute($tag,$tag,$tag,$tag,$tag,$tag,$tag,$tag);
  return $sth;
}

sub meta_select {
  my ($self) = @_;
  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  my $st = <<EOS;
SELECT
min(min_timestamp) AS min_timestamp,
max(max_timestamp) AS max_timestamp,
count(distinct r.service) AS services,
$fields
FROM service_report AS r
WHERE r.location=?
EOS
  return $st;
}

sub tag_select {
  my ($self) = @_;

  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  return <<EOS;
SELECT r.service as tag,
count(distinct r.name) AS services,
$fields
FROM service_report r
WHERE r.location=?
GROUP BY r.service
ORDER BY r.service
;
EOS
}


sub nav_response {
  my ($self) = @_;
  return <<EOS;
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u
INNER JOIN navigation AS n ON n.upload=u.id
WHERE u.location=? AND tabclosed>0
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u
INNER JOIN navigation AS n ON n.upload=u.id
WHERE u.location=? AND response500>0
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u
INNER JOIN navigation AS n ON n.upload=u.id
WHERE u.location=? AND response400>0
UNION
SELECT utimestamp AS timestamp, '300' AS measure,response300 AS amount 
FROM current AS u
INNER JOIN navigation AS n ON n.upload=u.id
WHERE u.location=? AND response300>0;
EOS
}

sub nav_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->nav_response)
   or die $!;
  my $tag = $self->{location};
  $sth->execute($tag,$tag,$tag,$tag);
  return $sth;
}

sub response_histogram {
  my ($self,$reqtype) = @_;
  return <<EOS;
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u
INNER JOIN $reqtype AS n ON n.upload=u.id
WHERE u.location=? AND tabclosed>0
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u
INNER JOIN $reqtype AS n ON n.upload=u.id
WHERE u.location=? AND response500>0
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u
INNER JOIN $reqtype AS n ON n.upload=u.id
WHERE u.location=? AND response400>0
;
EOS
}

sub nreq_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $tag = $self->{location};
  my $sth =
    $dbh->prepare($self->response_histogram("update_request"))
      or die $!;
  $sth->execute($tag,$tag,$tag);
  return $sth;
}

sub ureq_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $tag = $self->{location};
  my $sth =
    $dbh->prepare($self->response_histogram("update_request"))
      or die $!;
  $sth->execute($tag,$tag,$tag);
  return $sth;
}

sub location {
  undef;
}

1;
