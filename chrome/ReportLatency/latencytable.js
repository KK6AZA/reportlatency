var latency_table_navigations = {};

function writeLatencyTable() {
    var t = document.getElementById('latency_table');
    var html = `
      <tr>
	<th>Name</th> <th> Navigations </th> <th> Requests </th> <th> Latency (ms) </th>
      </tr>
`;
    var sorted_services = Object.keys(latency_table_navigations).sort()
    for (var i in sorted_services) {
	var service = sorted_services[i];
	var stat = latency_table_navigations[service];
	html = html + "<tr> " +
	    "<td> " + service + " </td> " +
	    "<td align=right> " + stat.count() + "</td> " +
	    "<td> " + " </td> " +
	    "<td align=right> " + Math.round(stat.average()) + "</td> " +
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

