
/**
 * @fileoverview LatencyData is the top level data object for ReportLatency.
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
 * Class containing all data for ReportLatency
 * @constructor
 */
function LatencyData() {
  this.tab = {};
  this.stats = new ServiceStats();
  if ('runtime' in chrome) {
    if (typeof ( chrome.runtime.getManifest ) == 'function') {
      this.manifest = chrome.runtime.getManifest();
    }
  }
}


/**
 * Records a start of a web request.
 *
 * @param {object} data is the callback data for Chrome's onBeforeRequest()
 *
 */
LatencyData.prototype.startRequest = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      if (data.type == 'main_frame') {
	var service = this.tab[data.tabId].service;
	if (service) {
	  delete this.tab[data.tabId]['service'];
	  this.tab[data.tabId] = new TabData();
	}
      }
      this.tab[data.tabId].startRequest(data);
    } else {
      if (data.tabId >= 0) {
	if (localStorage['debug_tabs'] == 'true' ||
	    localStorage['debug_requests'] == 'true') {
	  console.log('tabId ' + data.tabId + ' not started');
	}
      }
    }
  } else {
    console.log('malformed data in startRequest - no tabId');
  }
};

/**
 * Records end of a web request.
 *
 * @param {object} data is the callback data for Chrome's onCompletedRequest()
 *
 */
LatencyData.prototype.endRequest = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].endRequest(data);
    } else {
      if (localStorage['debug_requests'] == 'true') {
	logObject(data.tabId + ' tabId not found in endRequest()', data);
      }
    }
  } else {
    if (localStorage['debug_requests'] == 'true') {
      logObject('malformed data in endRequest - no tabId', data);
    }
  }
};

/**
 * Records end of a web request.
 *
 * @param {object} data is the callback data for Chrome's onErrorRequest()
 *
 */
LatencyData.prototype.deleteRequest = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].deleteRequest(data);
    } else {
      if (localStorage['debug_requests'] == 'true') {
	logObject(data.tabId + ' tabId not found in deleteRequest', data);
      }
    }
  } else {
    if (localStorage['debug_requests'] == 'true') {
      logObject('malformed data in deleteRequest - no tabId', data);
    }
  }
};

/**
 * Delete the appropriate TabData object when tab is removed.
 *
 * @param {number} tabId is the callback data for Chrome's onRemoved()
 * @param {object} removeInfo is the callback data for Chrome's onRemoved()
 *
 */
LatencyData.prototype.tabRemoved = function(tabId, removeInfo) {
  if (localStorage['debug_tabs'] == 'true') {
    logObject('LatencyData.tabRemoved(' + tabId + ')',
	      removeInfo);
  }
  if (tabId in this.tab) {
    this.tab[tabId].tabRemoved(removeInfo);
    var navigation = this.tab[tabId].navigation;
    if (navigation) {
      var service = aggregateName(this.tab[tabId].navigation.url);
      this.stats.transfer(service, this.tab[tabId].stat);
    }
    delete this.tab[tabId];
  } else {
    if (localStorage['debug_tabs'] == 'true') {
      console.log('  missing tabId ' + tabId + ' received in tabRemoved()');
    }
  }
}

/**
 * Records a start of a navigation.
 *
 * @param {object} data is the callback data for Chrome's onBeforeNavigate()
 *
 */
LatencyData.prototype.startNavigation = function(data) {
    if ('tabId' in data) {
	if (!(data.tabId in this.tab)) {
	    //  if (('parentFrameId' in data) && (data.parentFrameId < 0)
	    //  normally only necessary to create when these features present,
	    //  but on extension restart may need to create also  
	    this.tab[data.tabId] = new TabData();
	}
	this.tab[data.tabId].startNavigation(data);
    } else {
	logObject('malformed data in startNavigation - no tabId', data);
    }
};

/**
 * Records end of a navigation.
 * Handles tasks postponed until service name was known.
 *
 * @param {object} data is the callback data for onCompletedNavigation()
 *
 */
LatencyData.prototype.endNavigation = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].endNavigation(data);
      if ('service' in this.tab[data.tabId]) {
	var service = this.tab[data.tabId].service;
	this.stats.transfer(service, this.tab[data.tabId].stat);
	/* this.postLatency(service); */
      }
    } else {
      console.log(data.tabId + ' tabId not found in endNavigation');
    }
  } else {
    console.log('malformed data in endNavigation - no tabId');
  }
};

/**
 * Records end of a web navigation..
 *
 * @param {object} data is the callback data for Chrome's onErrorOccurred()
 *
 */
LatencyData.prototype.deleteNavigation = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].deleteNavigation(data);
    } else {
      logObject(data.tabId + ' tabId not found in deleteNavigation()', data);
    }
  } else {
    logObject('malformed data in deleteNavigation() - no tabId', data);
  }
};



/**
 * summary() returns data aggregated by navigation, for summaries
 *
 **/
LatencyData.prototype.summary = function() {
    return this.stats.summary();
}

/**
 *
 * @param {string} measurement type of latency.
 * @param {string} result name for latency type.
 * @returns {number} the total number of events returning the result.
 */
LatencyData.prototype.countable = function(measurement, result) {
  return this.stats.countable(measurement, result);
};
