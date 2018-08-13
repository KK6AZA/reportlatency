var latency_table_counter = 0;

var latency_table_navigations = {};

function writeLatencyTable() {
    var t = document.getElementById('latency_table');
    latency_table_counter++;
    var html = '<tr> <dt>' + latency_table_counter + "</dt> </tr>\n";
    html = html + `
      <tr>
	<th>Name</th> <th> Count </th> <th> Latency </th>
      </tr>
`;
    for (var servicename in latency_table_navigations) {
	var stat = latency_table_navigations[servicename];
	logObject("latency_table_navigations[" + servicename + "]", stat);
	html = html + "<tr> <td> " + servicename + " </td> <td> " +
	    stat.count() + "</td> <td> " +
	    Math.round(stat.average()) + "</td> </tr>\n";
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
	logObject("response.navigations[" + service + "]",
		  response.navigations[service]);
	navigations[service] = new Stat(response.navigations[service]);
	logObject("navigations[" + service + "]", navigations[service]);
    }
    latency_table_navigations = navigations;
    writeLatencyTable();
}

