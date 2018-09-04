
/**
 * @fileoverview major_tests.js has unit tests for the functions in
 *    major_services.js.
 * @author dld@debian.org (DrakeDiedrich)
 *
 * Copyright 2018 Google Inc. All Rights Reserved.
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

test('majorName', function() {
  equal(majorName
      ('www.facebook.com', ''),
      'facebook.com',
      'www.facebook.com');
  equal(majorName
      ('amazon.com', ''),
      'amazon.com',
      'amazon.com');
  equal(majorName
      ('mail.google.com', 'mail/u/0/?shva=1#search/qunit'),
      'google.com',
      'mail.google.com');
  equal(majorName
      ('service.company.com', 'path'),
      null,
      '!service.company.com');
});

