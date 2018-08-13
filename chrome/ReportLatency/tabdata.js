
/**
 * @fileoverview TabData is a container for all temporary stats by tabId,
 *   until the final service name is known and they are transfered to
 *   a ServiceStats object.
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



/**
 * Class containing of multiple types of latencies
 * @constructor
 */
function TabData() {
  this.stat = new NameStats();
  this.request = {};
  this.tabupdate = {};
}

/**
 * Adds a new measurement
 *
 * @param {object} data about the request from Chrome onBeforeRequest().
 *
 */
TabData.prototype.startRequest = function(data) {
  if (localStorage['debug_requests'] == 'true' ||
      (data.type == 'main_frame' &&
       localStorage['debug_navigations'] == 'true')) {
    logObject('TabData(' + this.service + ').startRequest()', data);
  }
  if (data.type == 'main_frame') {
    if ('service' in this) {
      delete this['service'];
    }
  }

  if ('requestId' in data) {
    if (data.requestId in this.request) {
      var data1 = Object.create(this.request[data.requestId]);
      if (localStorage['debug_requests'] == 'true') {
	logObject('new interleaved requestId ' + data.requestId, data);
	logObject('old interleaved requestId ' + data1.requestId, data1);
      }
      data1.timeStamp = data.timeStamp;
      data1.statusCode = data.statusCode;
      this.endRequest(data1);
    }
    this.request[data.requestId] = data;
  } else {
    if (localStorage['debug_requests'] == 'true') {
      console.log('missing requestId in startRequest() data');
    }
  }
};

/**
 * Adds a new measurement
 *
 * @param {object} data about the request from Chrome onCompletedRequest().
 *
 */
TabData.prototype.endRequest = function(data) {
  if (localStorage['debug_requests'] == 'true' ||
      (data.type == 'main_frame' &&
       localStorage['debug_navigations'] == 'true')) {
    logObject('TabData(' + this.service + ').endRequest()', data);
  }

  if (data.statusCode) {
    if (data.type == 'main_frame') {
      this.mainFrameStatusCode = data.statusCode;
    }
  } else {
    logObject('endRequest w/o statusCode', data);
  }

  if ('requestId' in data) {
    if (data.requestId in this.request) {
      if (('url' in data) &&
	  (data.url == this.request[data.requestId].url)) {
	var name = aggregateName(data.url);
	if (name) {
	  if (!data.fromCache) {
	    var delay = data.timeStamp -
	      this.request[data.requestId].timeStamp;
	    if (localStorage['log_requests'] == 'true' ||
		(data.type == 'main_frame' &&
		 localStorage['log_navigations'] == 'true')) {
		console.log(name + ' (' + this.service + ') requests +' +
			    delay + ' ms');
	    }
	    var latencyType='nreq';
	    if (this.service) {
	      latencyType='ureq';
	    }
	    this.stat.add(name, latencyType, delay);
	    /* TODO: not keeping status code data currently, but it can be captured here
	    if (data.statusCode) {
	      var family = statusCodeFamily(data.statusCode);
	      if (family) {
		this.stat.increment(name, latencyType, 'r' + family);
	      }

	    } */
	  }
	} else {
	  if (localStorage['debug_requests'] == 'true') {
	    logObject('no service name in endRequest()', data);
	  }
	}
      } else {
	if (localStorage['debug_requests'] == 'true') {
	  logObject('missing or mismatched data.url in endRequest()', data);
	}
      }
      delete this.request[data.requestId];
    } else {
      if (localStorage['debug_requests'] == 'true') {
	logObject('requestId ' + data.requestId + ' not found in endRequest',
		  data);
      }
    }
  } else {
    if (localStorage['debug_requests'] == 'true') {
      logObject('missing requestId in endRequest()', data);
    }
  }
};

/**
 * Delete a request (due to an error).
 *
 * @param {object} data about the request from Chrome onErrorRequest().
 *
 */
TabData.prototype.deleteRequest = function(data) {
  if (localStorage['debug_requests'] == 'true') {
    logObject('TabData(' + this.service + ').deleteRequest()', data);
  }
  if ('requestId' in data) {
    if (data.requestId in this.request) {
      delete this.request[data.requestId];
    } else {
      if (localStorage['debug_requests'] == 'true') {
	console.log('requestId ' + data.requestId +
		    ' not found in deleteRequest()');
      }
    }
  } else {
    if (localStorage['debug_requests'] == 'true') {
      console.log('missing requestId in deleteRequest() data');
    }
  }
};


/**
 * startNavigation() is a callback for when a Navigation event starts.
 *
 * @param {object} data about the navigation from Chrome onBeforeNavigation().
 *
 */
TabData.prototype.startNavigation = function(data) {
  if (('parentFrameId' in data) && (data.parentFrameId < 0)) {
    if (localStorage['debug_navigations'] == 'true') {
      logObject('TabData.startNavigation()', data);
    }
    if ('service' in this) {
      delete this['service'];
    }
    if ('url' in data) {
      if (isWebUrl(data.url)) {
	if ('timeStamp' in data) {
	  this.navigation = data;
	  if (localStorage['debug_navigations'] == 'true') {
	    console.log('  starting navigation');
	  }
	} else {
	  if (localStorage['debug_navigations'] == 'true') {
	    console.log('missing timeStamp in startNavigation() data');
	  }
	}
      } else {
	if (localStorage['debug_navigations'] == 'true') {
	  console.log('startNavigation(' + data.url + ') not web');
	}
      }
    } else {
      if (localStorage['debug_navigations'] == 'true') {
	console.log('no url found in startNavigation() data');
      }
    }
  } else {
    // console.log('  Meh.  Don\'t care about subframe navigation events.');
  }
};

/**
 * endNavigation() is a callback for when a Navigation event completes.
 *
 * @param {object} data about the navigation from Chrome onCompletedNavigation().
 *
 */
TabData.prototype.endNavigation = function(data) {
  if (('frameId' in data)) {
    if ('navigation' in this) {
      if (data.frameId == this.navigation.frameId) {
	if (localStorage['debug_navigations'] == 'true') {
	  logObject('TabData.endNavigation()', data);
	}
	if ('url' in data) {
	  if (isWebUrl(data.url)) {
	    if ('timeStamp' in data) {
	      var delay = data.timeStamp - this.navigation.timeStamp;
	      var original_name = aggregateName(this.navigation.url);
	      this.service = aggregateName(data.url);
	      if (localStorage['log_navigations'] == 'true') {
		console.log(original_name + ' (' + this.service +
			    ') navigations +' + delay + ' ms');
	      }
	      this.stat.add(original_name, 'nav', delay);
	      /* if (this.mainFrameStatusCode) {
		var family = statusCodeFamily(this.mainFrameStatusCode);
		if (family) {
		  if (localStorage['log_navigations'] == 'true') {
		    console.log('incrementing navigation status code ' +
				family);
		  }
		  this.stat.increment(original_name, 'nav', 'r' + family);
		}
	      } */
	    } else {
	      if (localStorage['debug_navigations'] == 'true') {
		console.log('missing timeStamp in endNavigation() data');
	      }
	    }
	  } else {
	    if (localStorage['debug_navigations'] == 'true') {
	      console.log('endNavigation(' + data.url + ') not web');
	    }
	  }
	} else {
	  if (localStorage['debug_navigations'] == 'true') {
	    console.log('no url found in endNavigation() data');
	  }
	}
	delete this['navigation'];
      } else {
	// console.log('  Meh. Don\'t care about subframes again.');
      }
    } else {
      if (localStorage['debug_navigations'] == 'true') {
	console.log('no navigation found for tab ' + data.tabId +
		    'frame ' + data.frameId);
      }
    }
  } else {
    if (localStorage['debug_navigations'] == 'true') {
      console.log('no frameId found');
    }
  }
};

/**
 * deleteNavigation() is a callback for when a Navigation event completes
 *   but should not be added to the statistics.  Use this for failures to
 *   clean up.
 *
 * @param {object} data about the navigation from Chrome
 *
 */
TabData.prototype.deleteNavigation = function(data) {
  if (data.frameId == 0) {
    if (localStorage['debug_navigations'] == 'true') {
      logObject('TabData.deleteNavigation(data)', data);
    }
    if ('navigation' in this) {
      if ('error' in data) {
	if (data.error == 'net::ERR_ABORTED') {
	  this.nav_aborted = aggregateName(data.url);
	}
      }
      delete this['navigation'];
    } else {
      if (localStorage['debug_navigations'] == 'true') {
	console.log('  current navigation not found');
      }
    }
  }
};

/**
 * Callback when a tab is removed by the browser.  Increment tabclosed
 * for the open requests and navigations and the total time since the
 * requests and navigations were launched until the tab was removed.
 *
 */
TabData.prototype.tabRemoved = function(removeInfo) {
  if (!('service' in this)) {
    if (localStorage['debug_tabs'] == 'true') {
      console.log('  tab.service not yet defined');
    }
    if ('navigation' in this) {
      if ('url' in this.navigation) {
	// received before the deleteNavigation() event
	var name = aggregateName(this.navigation.url);
	/* this.stat.increment(name, 'nav', 'tabclosed'); */
	var delay = removeInfo.timeStamp - this.navigation.timeStamp;
	this.stat.add(name, 'nav', delay);
	if (localStorage['debug_tabs'] == 'true') {
	  console.log('  increment tabclosed for ' + name);
	}
      } else {
	if (localStorage['debug_tabs'] == 'true') {
	  console.log('  no navigation.url');
	}
      }
      for (var r in this.request) {
	logObject('tab_deleted TabData.request[' + r + ']',this.request[r]);
	var name = aggregateName(this.request[r].url);
	/* this.stat.increment(name, 'nreq', 'tabclosed'); */
	var delay = removeInfo.timeStamp - this.request[r].timeStamp;
	this.stat.add(name, 'nreq', delay);
	if (localStorage['debug_tabs'] == 'true') {
	  console.log('  increment nreq[' + name + '].tabclosed');
	}
      }
    } else {
      if ('nav_aborted' in this) {
	// received after the deleteNavigation() event
	var name = this.nav_aborted;
	var delay = removeInfo.timeStamp - this.request[r].timeStamp;
	this.stat.add(name, 'nav', delay);
	/* this.stat.increment(name, 'nav', 'tabclosed'); */
	if (localStorage['debug_tabs'] == 'true') {
	  console.log('  increment navigation[' + name + '].tabclosed');
	}
	for (var r in this.request) {
	  if (localStorage['debug_tabs'] == 'true') {
	    logObject('nav_aborted TabData.request[' + r + ']',
		      this.request[r]);
	  }
	  var name = aggregateName(this.request[r].url);
	  /* this.stat.increment(name, 'nreq', 'tabclosed'); */
	  var delay = removeInfo.timeStamp - this.request[r].timeStamp;
	  this.stat.add(name, 'nreq', delay);
	  if (localStorage['debug_tabs'] == 'true') {
	    console.log('  increment nreq[' + name + '].tabclosed');
	  }
	}
      } else {
	if (localStorage['debug_tabs'] == 'true') {
	  console.log('  no navigation');
	}
      }
    }
  } else {
    if (localStorage['debug_tabs'] == 'true') {
      console.log('  tab.service is already ' + this.service);
   }
   for (var r in this.request) {
     var name = aggregateName(this.request[r].url);
     /* this.stat.increment(name, 'ureq', 'tabclosed'); */
     var delay = removeInfo.timeStamp - this.request[r].timeStamp;
     this.stat.add(name, 'ureq', delay);
   }
  }
}
