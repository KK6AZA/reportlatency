var latency_table_counter = 0;

var latency_table_services = [];

function writeLatencyTable() {
    var t = document.getElementById('latency_table');
    latency_table_counter++;
    var html = '<tr> <dt>' + latency_table_counter + "</dt> </tr>\n";
    html = html + `
      <tr>
	<th>Name</th> <th> Count </th> <th> Latency </th>
      </tr>
`;
    for (var i=0; i<latency_table_services.length; i++) {
	html = html + "<tr> <td> " + latency_table_services[i] + " </td> </tr>\n";
    }
    html = html + '<tr> <hl> </tr>' + "\n";
    t.innerHTML = html;
}

function request_services() {
    chrome.runtime.sendMessage({ rpc: "get_services" }, recv_services);
}

document.addEventListener('DOMContentLoaded', function () {
    request_services();
    document.querySelector('button').addEventListener('click', request_services);
});

function recv_services(response) {
    logObject("recv_services(" + response + ")", response);
    var services = response.services;
    logObject("services: ", services);
    console.log("   services=" + services.length);
    latency_table_services = services;
    writeLatencyTable();
}

