
/**
 * @fileoverview This file contains QUnit tests for functions in functions.js
 * @author dld@google.com (DrakeDiedrich)
 *
 * Copyright 2014 Google Inc. All Rights Reserved.
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

test('statusCodeFamily', function() {
       equal(statusCodeFamily(null), null, 'null');
       equal(statusCodeFamily('string'), null, 'string');
       equal(statusCodeFamily('199'), null, '199');
       equal(statusCodeFamily('200'), 200, '200');
       equal(statusCodeFamily('304'), 300, '300');
       equal(statusCodeFamily('499'), 400, '400');
       equal(statusCodeFamily('500'), 500, '500');
       equal(statusCodeFamily('600'), null, '600');
});


test('aggregateName', function() {
  equal(aggregateName
      ('http://www.google.com/'),
      'www.google.com',
      'www.google.com');
  equal(aggregateName
      ('http://www.facebook.com/'),
      'facebook.com',
      'facebook.com');
  equal(aggregateName
      ('http://www.google.com/aclk%3Fsa%3D'),
      'www.google.com/aclk',
      'www.google.com/aclk');
  equal(aggregateName
      ('http://www.google.com:12345/'),
      'www.google.com',
      'www.google.com:12345');
  equal(aggregateName
      ('https://s0.2mdn.google.com/8025626/1532610381043/BUS_BDL_ENG_3490GrayCountdown_100…034%,%20rgb(160,%20160,%20160)%2050%,%20rgba(160,%20160,%20160,%200)%2060%'),
      '2mdn.google.com',
      'observed in wild from 2mdn.net, breaks native decoder');
});

/* test domain name flattening w/o needing to set default_as_org */
test('defaultDomain', function() {
  equal(defaultDomain
      ('www.company.ai'),
      'company.ai',
	'company.ai');
});

