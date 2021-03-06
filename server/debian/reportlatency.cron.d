#
# Regular cron jobs for the google-reportlatency-service package
#
#
# Copyright 2013,2014 Google Inc. All Rights Reserved.
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
#
#
PATH=/usr/local/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
MAILTO=""
1,31 * * * * www-data [ -x /usr/share/reportlatency/location.pl ] && cd /var/lib/reportlatency/www && /usr/share/reportlatency/location.pl >/dev/null 2>&1
6,36 * * * * www-data [ -x /usr/share/reportlatency/service.pl ] && cd /var/lib/reportlatency/www && /usr/share/reportlatency/service.pl >/dev/null 2>&1
11,41 * * * * www-data [ -x /usr/share/reportlatency/untagged.pl ] && cd /var/lib/reportlatency/www && /usr/share/reportlatency/untagged.pl >/dev/null 2>&1
21,51 * * * * www-data [ -x /usr/share/reportlatency/summary.pl ] && cd /var/lib/reportlatency/www && /usr/share/reportlatency/summary.pl >/dev/null 2>&1
26,56 * * * * www-data [ -x /usr/share/reportlatency/tag.pl ] && cd /var/lib/reportlatency/www && /usr/share/reportlatency/tag.pl >/dev/null 2>&1
01 4 * * * www-data cat /etc/reportlatency/tag.d/*.sql /var/lib/reportlatency/tag.d/*.sql > /var/lib/reportlatency/data/tag.sql ; /usr/bin/sqlite3 /var/lib/reportlatency/data/latency.sqlite3 </usr/share/reportlatency/update-tag.sql >/dev/null 2>&1
*/2 * * * * www-data /usr/bin/sqlite3 /var/lib/reportlatency/data/latency.sqlite3 '.backup /var/lib/reportlatency/data/tmp.sqlite3' && mv /var/lib/reportlatency/data/tmp.sqlite3 /var/lib/reportlatency/data/backup.sqlite3
