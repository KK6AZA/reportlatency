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

package ReportLatency::Base;

use strict;
use vars qw($VERSION);

$VERSION     = 0.1;

sub new {
  my $class = shift;
  my $self  = bless {}, $class;
  $self->{store} = shift;
  my $begin = $self->{begin} = shift;
  my $end = $self->{end} = shift;
  $self->{store}->create_current_temp_table($begin,$end);

  return $self;
}

sub DESTROY {
  my $self = shift;
}

sub title { return "Title"; }
sub name_title { return "Name"; }
sub count_title { return "Count"; }
sub meta_count_title { return "Count"; }

sub duration {
  my $self = shift;
  my $store = $self->{store};
  return $self->end - $self->begin;
}

sub begin {
  my $self = shift;
  my $store = $self->{store};
  return $store->db_to_unix($self->{begin});
}

sub end {
  my $self = shift;
  my $store = $self->{store};
  return $store->db_to_unix($self->{end});
}

sub execute {
    my ($self,$sth) = @_;
    my $rv = $sth->execute;
    return $rv if $rv;
    die $sth->errstr;
}

sub null_query {
  return 'SELECT NULL AS timestamp WHERE NULL!=NULL;';
}

sub latency_select {
  my $self = shift;
  return $self->null_query;
}

sub nav_latency_select {
  my ($self) = @_;
  return $self->latency_select('navigation');
}

sub nav_latencies {
  my $self = shift;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->nav_latency_select) or die $!;
  $self->execute($sth);
  return $sth;
}

sub nreq_latency_select {
  my ($self) = @_;
  return $self->latency_select('navigation_request');
}

sub nreq_latencies {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->nreq_latency_select) or die $!;
  $self->execute($sth);
  return $sth;
}

sub ureq_latency_select {
  my ($self) = @_;
  return $self->latency_select('update_request');
}

sub ureq_latencies {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->ureq_latency_select) or die $!;
  $self->execute($sth);
  return $sth;
}


sub meta_select {
  my ($self) = @_;
  return $self->null_query;
}

sub meta {
  my ($self) = @_;

  if (!defined $self->{meta}) {
    my $store = $self->{store};
    $store->create_service_report_temp_table();
    my $dbh = $store->{dbh};
    my $sth = $dbh->prepare($self->meta_select);
    $self->execute($sth);
    $self->{meta} = $sth->fetchrow_hashref;
  }

  return $self->{meta};
}

sub tag_url {
  return undef;
}

sub tag_select {
  my ($self) = @_;
  return $self->null_query;
}

sub tag {
  my ($self) = @_;

  my $store = $self->{store};

  $store->create_service_report_temp_table();

  my $dbh = $store->{dbh};
  my $fields = $store->common_aggregate_fields();
  my $sth = $dbh->prepare($self->tag_select ) or die $!;
  $self->execute($sth);
  return $sth;
}


sub location_select {
  my ($self) = @_;
  return $self->null_query;
}

sub location {
  my ($self) = @_;

  my $store = $self->{store};
  my $dbh = $store->{dbh};
  my $sth = $dbh->prepare( $self->location_select ) or die $!;
  $self->execute($sth);
  return $sth;
}

sub latency_histogram {
  my ($self,$latency) = @_;
  return $self->null_query;
}

sub nav_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('navigation'))
   or die $!;
  $self->execute($sth);
  return $sth;
}

sub nav_response {
  my ($self) = @_;
  return $self->null_query;
}

sub nav_response_histogram {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare( $self->nav_response ) or die $!;
  $self->execute($sth);
  return $sth;
}


sub nreq_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('navigation_request') )
    or die $!;
  $self->execute($sth);
  return $sth;
}

sub response_histogram {
  my ($self,$reqtype) = @_;
  return $self->null_query;
}

sub nreq_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare($self->response_histogram("navigation_request") )
      or die $!;

  $self->execute($sth);
  return $sth;
}

sub ureq_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('update_request') )
    or die $!;
  $self->execute($sth);
  return $sth;
}

sub ureq_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare($self->response_histogram("update_request"))
      or die $!;
  $self->execute($sth);
  return $sth;
}

1;
