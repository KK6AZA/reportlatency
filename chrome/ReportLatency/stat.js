
/**
 * @fileoverview Stat holds enough composite data on a series of
 *     measurements to partially reconstruct the measurement distribution.
 *     Right now it holds just high, low, total and count, allowing
 *     average and range to be computed.
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
 * Class holding measurements that can reconstruct a range and average.
 * Also holds count of errors and interrupts for different events.
 * @constructor
 */
function Stat(data) {
    if (data) {
	if (data.d) {
	    this.d = data.d;
	} else if (data.n) {
	    this.n = data.n;
	    this.t = data.t;
	    this.l = data.l;
	    this.h = data.h;
	}
    }
}

/* functions to read out statistical values */
Stat.prototype.count = function() {
    if (this.n) {
	return this.n;
    } else if (this.d) {
	return this.d.length;
    } else {
	return 0;
    }
}

Stat.prototype.high = function() {
    if (this.h) {
	return this.h;
    } else if (this.d) {
	var h = this.d[0];
	for (var i=1; i<this.d.length; i++) {
	    if (this.d[i] > h) {
		h = this.d[i];
	    }
	}
	return h;
    } else if (this.n == 1) {
	return this.t;
    } else if (this.n == 2 && this.l) {
	return this.t - this.l;
    } else {
	return undefined;
    }
}

Stat.prototype.low = function() {
    if (this.l) {
	return this.l;
    } else if (this.d) {
	var l = this.d[0];
	for (var i=1; i<this.d.length; i++) {
	    if (this.d[i] < l) {
		l = this.d[i];
	    }
	}
	return l;
    } else if (this.n == 1) {
	return this.t;
    } else if (this.n == 2 && this.h) {
	return this.t - this.h;
    } else {
	return undefined;
    }
}

Stat.prototype.average = function() {
    if (this.count() > 0) {
	return this.total() / this.count();
    }
    return undefined;
}

Stat.prototype.total = function() {
    if (this.t) {
	return this.t;
    } else if (this.d) {
	var t=0;
	for (var i=0; i<this.d.length; i++) {
	    t += this.d[i];
	}
	return t;
    } else {
	return undefined;
    }
}



/**
 * Adds a new measurement to a Stat (statistical measurement).
 * Limited data on the distribution is maintained, currently just
 * average, high, and low value.
 *
 * @param {number} delta The is a new measurement to incorporate in the stat.
 */
Stat.prototype.add = function(delta) {
    if (this.count() == 0) {
	this.d = [ delta ];
    } else if (this.d) {
	this.d.push(delta);

	if (this.d.length > 3) {
	    this.t=0;
	    this.n = this.d.length;
	    this.l = this.h = this.d[0];
	    for (var i=0; i<this.d.length; i++) {
		this.t += this.d[i];
		if (this.d[i] < this.l) {
		    this.l = this.d[i];
		}
		if (this.d[i] > this.h) {
		    this.h = this.d[i];
		}
	    }
	    delete this['d'];
	}
    } else {
	this.n++;
	this.t += delta;
	if (delta < this.l) {
	    this.l = delta;
	}
	if (delta > this.h) {
	    this.h = delta;
	}
    }	
    /* TODO: bins to keep more distribution information */
};


/**
 * Combine two measurements, zeroing one and transfering all counts to this
 *
 * @this {Stat}
 * @param {Object} stat The stat to transfer into this and zero.
 */
Stat.prototype.transfer = function(stat) {
    if (stat.d) {
	if (this.count() == 0) {
	    this.d = stat.d;
	} else {
	    for (var i=0; i<stat.d.length; i++) {
		this.add(stat.d[i]);
	    }
	}
	delete stat['d'];
    } else {
	if (stat.h) {
	    this.add(stat.h);
	    stat.t -= stat.h;
	    stat.n--;
	    delete stat['h'];
	}
  
	if (stat.l) {
	    this.add(stat.l);
	    stat.t -= stat.l;
	    stat.n--;
	    delete stat['l'];
	}

	if (this.n) {
	    this.n += stat.n;
	    this.t += stat.t;
	} else {
	    var avg = stat.t/stat.n;
	    while (! this.n) {
		this.add(avg);
		stat.t -= avg;
		stat.n--;
	    }
	    this.t += stat.t;
	    this.n += stat.n;
	    delete stat['t'];
	    delete stat['n'];
	}
    }		
};

