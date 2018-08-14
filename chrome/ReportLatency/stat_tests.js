
/**
 * @fileoverview This file contains QUnit tests for the Stat object.
 * @author dld@google.com (DrakeDiedrich)
 *
 * Copyright 2013,2014 Google Inc. All Rights Reserved.
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

test('Stat.add', function() {
    var s = new Stat();
    equal(s.count(), 0, 'empty count');
    equal(s.total(), undefined, 'empty total');
    equal(s.high(), undefined, 'empty high');
    equal(s.low(), undefined, 'empty low');

    s.add(550);
    equal(s.count(), 1, 'single count');
    equal(s.total(), 550, 'single total');
    equal(s.high(), 550, 'single high');
    equal(s.low(), 550, 'single low');

    s.add(30);
    equal(s.count(), 2, 'double count');
    equal(s.total(), 580, 'double total');
    equal(s.high(), 550, 'double high');
    equal(s.low(), 30, 'double low');

    s.add(1500);
    equal(s.count(), 3, 'triple count');
    equal(s.total(), 2080, 'triple total');
    equal(s.high(), 1500, 'triple high');
    equal(s.low(), 30, 'triple low');

    s.add(1200);
    equal(s.count(), 4, 'quad count');
    equal(s.total(), 3280, 'quad total');
    equal(s.high(), 1500, 'quad high');
    equal(s.low(), 30, 'quad low');
});


test('Stat.transfer', function() {
    var s = new Stat();
    var t = new Stat();
    t.add(10);

    s.transfer(t);

    equal(t.n, undefined, 'empty tmp count');
    equal(t.t, undefined, 'empty tmp total');
    equal(t.h, undefined, 'empty tmp high');

    equal(s.count(), 1, 'first transfer count');
    equal(s.total(), 10, 'first transfer total');
    equal(s.high(), 10, 'first transfer high');

    t.add(12);
    t.add(9);
    t.add(3);

    s.transfer(t);

    equal(t.n, undefined, 'empty tmp count');
    equal(t.t, undefined, 'empty tmp total');
    equal(t.h, undefined, 'empty tmp high');

    equal(s.count(), 4, 'second transfer count');
    equal(s.total(), 34, 'second transfer total');
    equal(s.high(), 12, 'second transfer high');

    t.add(2);

    s.transfer(t);

    equal(s.count(), 5, 'third transfer count');
    equal(s.total(), 36, 'third transfer total');
    equal(s.high(), 12, 'third transfer high');
});

test('Stat.add_stat', function() {
    var s = new Stat();
    var t = new Stat();
    t.add(10);

    s.add_stat(t);

    equal(s.count(), 1, 'first add_stat count');
    equal(s.total(), 10, 'first add_stat total');
    equal(s.low(), 10, 'first add_stat low');
    equal(s.high(), 10, 'first add_stat high');
    equal(t.count(), 1, 'tmp add_stat count');
    equal(t.total(), 10, 'tmp add_stat total');

    t.add(5);
    s.add_stat(t);

    equal(s.count(), 3, 'second add_stat count');
    equal(s.total(), 25, 'second add_stat total');
    equal(s.low(), 5, 'second add_stat low');
    equal(s.high(), 10, 'second add_stat high');
    equal(t.count(), 2, 'tmp add_stat count');
    equal(t.total(), 15, 'tmp add_stat total');
    equal(t.low(), 5, 'tmp add_stat high');
    equal(t.high(), 10, 'tmp add_stat high');
});

