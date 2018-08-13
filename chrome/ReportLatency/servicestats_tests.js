
/**
 * @fileoverview This file contains QUnit tests for the ServiceStats object.
 * @author dld@google.com (DrakeDiedrich)
 *
 * Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

test('ServiceStats.add', function() {
    var s = new ServiceStats();

    s.add('service', 'name', 'navigation', 5);
    equal(s.stat['service'].stat['name'].stat['navigation'].count(),
	1, 'single count');
    equal(s.stat['service'].stat['name'].stat['navigation'].total(),
	5, 'single total');
});

test('ServiceStats.transfer', function() {
    var s = new ServiceStats();
    var n = new NameStats();

    n.add('name', 'navigation', 3);
    s.transfer('service', n);
    equal(n.empty(), false, 'NameStats not empty');
    equal(s.stat['service'].stat['name'].stat['navigation'].count(), 1,
	  '1 navigations added');

    n.add('name', 'request', 2);
    equal(s.stat['service'].stat['name'].stat['request'].count(), 1,
	  '1 request passed through');

    n = new NameStats();
    n.add('name', 'navigation', 5);
    s.transfer('service', n);
    equal(n.empty(), true, 'NameStats now empty');
    equal(s.stat['service'].stat['name'].stat['navigation'].count(), 2,
	  '2 navigations added');
});

test('ServiceStats.best', function() {
  var s = new ServiceStats();

  s.add('service', 'server', 'nav', 5);
  s.add('service', 'redirector', 'nav', 10);
  s.add('content', 'server2', 'nreq', 1);
  s.add('current', 'server3', 'nav', 1);
  s.add('current', 'server3', 'nav', 2);
  s.add('current', 'server3', 'nav', 3);

  equal(s.best('current'), 'service',
	'service that isn\'t in use with most navigations chosen');
});

test('ServiceStats.delete', function() {
  var s = new ServiceStats();

  s.add('service', 'server', 'navigation', 5);
  s.add('service', 'redirector', 'navigation', 10);
  
  s.delete('service');
  ok(!('service' in s.stat),'service deleted');
});

test('ServiceStats.toJSON', function() {
  var s = new ServiceStats();

  s.add('service', 'server', 'navigation', 5);
  
  var jtxt = JSON.stringify(s);
  var obj = JSON.parse(jtxt);

  ok('service' in obj,'obj.service');
  ok('server' in obj.service,'obj.service.server');
  ok('navigation' in obj.service.server,'obj.service.server.navigation');
  ok('d' in obj.service.server.navigation,
     'obj.service.server.navigation.d');
  equal(obj.service.server.navigation.d.length, 1, '1 server navigation');
  equal(obj.service.server.navigation.d[0], 5, 'server navigation value');
});

