# Copyright 2013 Google Inc. All Rights Reserved.
# Copyright 2017 Drake Diedrich  All Rights Reserved.
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

TARGETS=ReportLatency.zip ReportLatency.xpi
GENERATED=eventPage.js options.js
SHIP=manifest.json icon128.png eventPage.js options.js latencytable.js options.html unittests.html

OPTION_SOURCE:=$(shell ls -1 option_*.js 2>/dev/null)

SERVICE_SOURCE:=$(shell ls -1 *_services.js 2>/dev/null)

TEST_SOURCE:=$(shell ls -1 *_tests.js 2>/dev/null)

GLOBAL_DEFAULTS:=$(shell ls -1 global_*.js 2>/dev/null)

SOURCE=functions.js stat.js latencystats.js namestats.js servicestats.js tabdata.js latencydata.js

all: $(TARGETS)

eventPage.js: globals.js $(GLOBAL_DEFAULTS) $(SOURCE) $(SERVICE_SOURCE) handlers.js
	cat $^ >$@

options.js: globals.js $(GLOBAL_DEFAULTS) $(OPTION_SOURCE)
	cat $^ >$@

ReportLatency.zip: $(SHIP) ship.txt
	cd .. ; zip ReportLatency/$@ `cat ReportLatency/ship.txt`

ReportLatency.xpi: install.rdf $(SHIP)
	zip $@ $^

clean:
	rm -f $(TARGETS) $(GENERATED)

