
/**
 * @fileoverview major_services.js has functions that add on to the
 *    default URL-flattening function, and generate specific service names
 *    for many major services.
 * @author dld@debian.org (DrakeDiedrich)
 *
 * Copyright 2018 Drake Diedrich All Rights Reserved.
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

var major_three_ld_function_map = {
    'amazon.co.uk': threeLevelDomain,
    'bbc.co.uk': threeLevelDomain,
    'telegraph.co.uk': threeLevelDomain,
    'dailymail.co.uk': threeLevelDomain,
    'guardian.co.uk': threeLevelDomain,
    'independent.co.uk': threeLevelDomain,
};

var major_two_ld_function_map = {
    'facebook.com': twoLevelDomain,
    'amazon.com': twoLevelDomain,
    'netflix.com': twoLevelDomain,
    'google.com': twoLevelDomain,
    'yahoo.com': twoLevelDomain,
    'instagram.com': twoLevelDomain,
    'linkedin.com': twoLevelDomain,
    'wordpress.org': twoLevelDomain,
    'pinterest.com': twoLevelDomain,
    'wikipedia.org': twoLevelDomain,
    'wordpress.com': twoLevelDomain,
    'blogspot.com': twoLevelDomain,
    'apple.com': twoLevelDomain,
    'tumblr.com': twoLevelDomain,
    'vimeo.com': twoLevelDomain,
    'flikr.com': twoLevelDomain,
    'microsoft.com': twoLevelDomain,
    'godaddy.com': twoLevelDomain,
    'qq.com': twoLevelDomain,
    'bit.ly': twoLevelDomain,
    'vk.com': twoLevelDomain,
    'reddit.com': twoLevelDomain,
    'w3.org': twoLevelDomain,
    'baidu.com': twoLevelDomain,
    'nytime.com': twoLevelDomain,
    't.co': twoLevelDomain,
    'europa.eu': twoLevelDomain,
    'wp.com': twoLevelDomain,
    'github.com': twoLevelDomain,
    'weebly.com': twoLevelDomain,
    'soundcloud.com': twoLevelDomain,
    'mozilla.org': twoLevelDomain,
    'yandex.ru': twoLevelDomain,
    'myspace.com': twoLevelDomain,
    'nih.gov': twoLevelDomain,
    'theguardian.com': twoLevelDomain,
    'cnn.com': twoLevelDomain,
    'stumbleupon.com': twoLevelDomain,
    'gravatar.com': twoLevelDomain,
    'digg.com': twoLevelDomain,
    'creativecommons.org': twoLevelDomain,
    'paypal.com': twoLevelDomain,
    'yelp.com': twoLevelDomain,
    'huffingtonpost.com': twoLevelDomain,
    'feedburner.com': twoLevelDomain,
    'issuu.com': twoLevelDomain,
    'wixsite.com': twoLevelDomain,
    'wix.com': twoLevelDomain,
    'dropbox.com': twoLevelDomain,
    'forbes.com': twoLevelDomain,
    'amazonaws.com': twoLevelDomain,
    'washingtonpost.com': twoLevelDomain,
    'bluehost.com': twoLevelDomain,
    'etsy.com': twoLevelDomain,
    'go.com': twoLevelDomain,
    'msn.com': twoLevelDomain,
    'wsj.com': twoLevelDomain,
    'ameblo.jp': twoLevelDomain,
    'archive.org': twoLevelDomain,
    'slideshare.net': twoLevelDomain,
    'eventbrite.com': twoLevelDomain,
    'sourceforge.net': twoLevelDomain,
    'parallels.com': twoLevelDomain,
    'mail.ru': twoLevelDomain,
    'ebay.com': twoLevelDomain,
    'livejournal.com': twoLevelDomain,
    'reuters.com': twoLevelDomain,
    'wikimedia.org': twoLevelDomain,
    'twitter.com': twoLevelDomain,
    'coderpad.io': twoLevelDomain,
    'xkcd.com': twoLevelDomain,
    'debian.org': twoLevelDomain,
    'typepad.com': twoLevelDomain,
    'box.com': twoLevelDomain,
    'bloomberg.com': twoLevelDomain,
    'bing.com': twoLevelDomain,
    'cdc.gov': twoLevelDomain,
    'latimes.com': twoLevelDomain,
    'aol.com': twoLevelDomain,
    'uber.com': twoLevelDomain,
    'lyft.com': twoLevelDomain,
    'doordash.com': twoLevelDomain,
    'grubhub.com': twoLevelDomain,
    'apache.org': twoLevelDomain,
    'nginx.org': twoLevelDomain,
    'kickstarter.com': twoLevelDomain,
    'imgur.com': twoLevelDomain,
    'wired.com': twoLevelDomain,
    'nasa.gov': twoLevelDomain,
    'surveymonkey.com': twoLevelDomain,
    'whatsapp.com': twoLevelDomain,
    'photobucket.com': twoLevelDomain,
    'ca.gov': twoLevelDomain,
    'buzzfeed.com': twoLevelDomain,
    'theatlantic.com': twoLevelDomain,
    'barnesandnoble.com': twoLevelDomain,
    'foxnews.com': twoLevelDomain,
    'cbsnews.com': twoLevelDomain,
    'techcrunch.com': twoLevelDomain,
    'booking.com': twoLevelDomain,
    'php.net': twoLevelDomain,
    'skype.com': twoLevelDomain,
    'whitehouse.gov': twoLevelDomain,
    'change.org': twoLevelDomain,
    'epa.gov': twoLevelDomain,
    'squarespace.com': twoLevelDomain,
    'cnbc.com': twoLevelDomain,
    'usnews.com': twoLevelDomain,
    'wikia.com': twoLevelDomain,
    'meetup.com': twoLevelDomain,
    'mapquest.com': twoLevelDomain,
    'economist.com': twoLevelDomain,
    'chicagotribune.com': twoLevelDomain,
    'newyorker.com': twoLevelDomain,
    'drupal.org': twoLevelDomain,
    'stackoverflow.com': twoLevelDomain,
    'mysql.com': twoLevelDomain,
    'postgresql.org': twoLevelDomain,
    'mozilla.com': twoLevelDomain,
    'ubuntu.com': twoLevelDomain,
    'redhat.com': twoLevelDomain,
    'python.org': twoLevelDomain,
    'perl.org': twoLevelDomain,
    'cpan.org': twoLevelDomain,
    'ticketmaster.com': twoLevelDomain,
    'slashdot.org': twoLevelDomain,
    'nextdoor.com': twoLevelDomain,
    'slate.com': twoLevelDomain,
    'djangoproject.com': twoLevelDomain,
    'mojolicious.org': twoLevelDomain,
    'nodejs.org': twoLevelDomain,
    'agilealliance.org': twoLevelDomain,
    'c2.com': twoLevelDomain,
    'catalystframework.org': twoLevelDomain,
    'rubyonrails.org': twoLevelDomain,
    'angular.io': twoLevelDomain,
    'zend.com': twoLevelDomain,
    'laravel.com': twoLevelDomain,
    'yiiframework.com': twoLevelDomain,
    'golang.org': twoLevelDomain,
    'thehill.com': twoLevelDomain,
    'grails.org': twoLevelDomain,
    'npr.org': twoLevelDomain,
    'pbs.org': twoLevelDomain,
    'pbskids.org': twoLevelDomain,
    'meteor.com': twoLevelDomain,
    'target.com': twoLevelDomain,
    'walmart.com': twoLevelDomain,
    'weather.com': twoLevelDomain,
    'dx.com': twoLevelDomain,
    'banggood.com': twoLevelDomain,
    'gearbest.com': twoLevelDomain,
    'aliexpress.com': twoLevelDomain,
    'adafruit.com': twoLevelDomain,
    'sfgate.com': twoLevelDomain,
    'mercurynews.com': twoLevelDomain,
};

var major_two_ld_string_map = {
    'youtube.com': 'google.com',
    'gmail.com': 'google.com',
    'messenger.com': 'facebook.com',
};


function majorName(host, path) {
  var domain2 = twoLevelDomain(host);
    
  var s = major_two_ld_string_map[domain2];
  if (s) {
      return s.toString();
  }

  var foo = major_two_ld_function_map[domain2];
  if (foo) {
      s = foo(host, path);
      return s.toString();
  }

  var domain3 = threeLevelDomain(host);
  foo = major_three_ld_function_map[domain3];
  if (foo) {
      s = foo(host, path);
      return s.toString();
  }

  return null;
}

registerService('majorServices',
    'Breaks down URLs to several major websites.  ' +
		'For instance facebook.com and yahoo.com',
    majorName);
