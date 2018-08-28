var latency_table_navigations = {};

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
    var sorted_services = Object.keys(latency_table_navigations).sort()
    for (var i in sorted_services) {
	var service = sorted_services[i];
	var stat = latency_table_navigations[service];
	html = html + "<tr> " +
	    "<td> " + service + " </td> " +
	    "<td align=right> " + stat.count() + "</td> " +
	    "<td align=right> " + Math.round(stat.low()) + "</td> " +
	    "<td align=right> " + Math.round(stat.average()) + "</td> " +
	    "<td align=right> " + Math.round(stat.high()) + "</td> " +
	    "</tr>\n";
    }
    html = html + '<tr> <hl> </tr>' + "\n";
    t.innerHTML = html;
}

function request_navigations() {
    chrome.runtime.sendMessage({ rpc: "get_navigations" }, recv_navigations);
}

document.addEventListener('DOMContentLoaded', function () {
    request_navigations();
    document.querySelector('button').addEventListener('click', request_navigations);
});

function recv_navigations(response) {
    var navigations = {};
    for (var service in response.navigations) {
	navigations[service] = new Stat(response.navigations[service]);
    }
    latency_table_navigations = navigations;
    writeLatencyTable();
}

