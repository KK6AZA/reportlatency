var latency_table_summary = {};

function int(s) {
    if (s>0) {
	return Math.round(s);
    } else {
	return '';
    }
}

function writeLatencyTable() {
    var t = document.getElementById('latency_table');
    var html = `
      <tr>
        <th>Name</th>
        <th colspan=4> Navigation </th>
        <th colspan=4> Navigation Request </th>
        <th colspan=4> Update Request </th>
      </tr>
      <tr>
        <th></th>
        <th> count </th> <th colspan=3>Latency(ms)</th>
        <th> count </th> <th colspan=3>Latency(ms)</th>
        <th> count </th> <th colspan=3>Latency(ms)</th>
      </tr>
      <tr>
        <th></th>
        <th> </th> <th>low</th> <th>avg</th> <th>high</th>
        <th> </th> <th>low</th> <th>avg</th> <th>high</th>
        <th> </th> <th>low</th> <th>avg</th> <th>high</th>
      </tr>
`;
    var sorted_services = Object.keys(latency_table_summary).sort()
    for (var i in sorted_services) {
	var service = sorted_services[i];
	var nav = latency_table_summary[service].nav;
	var nreq = latency_table_summary[service].nreq;
	var ureq = latency_table_summary[service].ureq;
	html = html + "<tr> " +
	    "<td> " + service + " </td> " +
	    "<td align=right> " + int(nav.count()) + "</td> " +
	    "<td align=right> " + int(nav.low()) + "</td> " +
	    "<td align=right> " + int(nav.average()) + "</td> " +
	    "<td align=right> " + int(nav.high()) + "</td> " +
	    "<td align=right> " + int(nreq.count()) + "</td> " +
	    "<td align=right> " + int(nreq.low()) + "</td> " +
	    "<td align=right> " + int(nreq.average()) + "</td> " +
	    "<td align=right> " + int(nreq.high()) + "</td> " +
	    "<td align=right> " + int(ureq.count()) + "</td> " +
	    "<td align=right> " + int(ureq.low()) + "</td> " +
	    "<td align=right> " + int(ureq.average()) + "</td> " +
	    "<td align=right> " + int(ureq.high()) + "</td> " +
	    "</tr>\n";
    }
    html = html + '<tr> <hl> </tr>' + "\n";
    t.innerHTML = html;
}

function request_summary() {
    chrome.runtime.sendMessage({ rpc: "get_summary" }, recv_summary);
}

document.addEventListener('DOMContentLoaded', function () {
    request_summary();
    document.querySelector('button').addEventListener('click', request_summary);
});

function recv_summary(response) {
    var summary = {};
    for (var service in response.summary) {
	summary[service] = {};
	for (var ltype in response.summary[service]) {
	    summary[service][ltype] = new Stat(response.summary[service][ltype]);
	}
    }
    latency_table_summary = summary;
    writeLatencyTable();
}

