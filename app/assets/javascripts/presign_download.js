//https://stackoverflow.com/a/5158301/3846548
function getParameterByName(name) {
    var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
    return match && decodeURIComponent(decodeURIComponent(match[1].replace(/\+/g, ' ')));
}

function getToken() {
  var loc = document.location.pathname;
  var arr = loc.split("/");
  if (arr.length > 1) {
    return arr[arr.length - 1];
  }
  return "";
}

function getCommand() {
  var loc = document.location.pathname;
  var arr = loc.split("/");
  if (arr.length > 2) {
    return arr[arr.length - 2];
  }
  return "";
}

function uuidv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function mockToken() {
  document.location = "/downloads/add/" + uuidv4();
}

function clearData() {
  localStorage.tokens = "";
  showTable();
}

function createRow(token, data) {
  var t = getTime();
  var tr = $("<tr/>");
  var href = "/downloads/get/"+token;
  if (data['ready']) {
    href += "?available=true";
  }
  var link = $("<a/>").attr("href", href).text(data['name'])
  $("<th/>").appendTo(tr).append(link);
  $("<td/>").appendTo(tr).text(formatTime(getTime(), data['available']));
  $("<td/>").appendTo(tr).text(formatTime(getTime(), data['expires']));
  $("<td/>").appendTo(tr).text(data['size']);
  return tr;
}

function getTokenData(token) {
  var datastr = localStorage[token];
  if (!datastr) {
    return null;
  }
  var data = JSON.parse(datastr);
  var t = getTime();
  if (data['expires'] < t) {
    localStorage.removeItem(token);
    return null;
  }
  data['ready'] = (data['available'] <= t);
  return data;
}

function showTable() {
  $("table.merritt_downloads tbody tr").remove();
  var tokens = getTokenList();
  var activeTokens = [];
  for (var i=0; i<tokens.length; i++) {
    var token = tokens[i];
    var data = getTokenData(token);
    if (data) {
      activeTokens.push(token)
      $("table.merritt_downloads tbody")
        .append(createRow(token, data));
    }
  }
}

function getTokenList() {
  if (localStorage.tokens == null || localStorage.tokens == "") {
    return [];
  }
  return localStorage.tokens.split(",");
}

function formatTime(t, comp) {
  var diff = comp - t;
  if (diff < 100) return 'Now';
  if (diff > 60000) return '' + Math.round(diff / 60000) + ' min';
  return '' + Math.round(diff / 1000) + ' sec';
}

function getTime() {
  return new Date().getTime();
}

function addToken(token) {
  if (token == "") {
    return;
  }
  var tokens = getTokenList();
  tokens.push(token);
  localStorage.tokens = tokens.join(",");
  var now = new Date();
  var d = new Date(getParameterByName('available'));

  data = {
    name: getParameterByName('key'),
    available: d.getTime(),
    expires: d.getTime() + 60 * 60000,
    size: getParameterByName('size')
  }
  localStorage[token] = JSON.stringify(data);
}

function initDialogs() {
  dialog = $("#download").dialog({
    autoOpen : false,
    height : 600,
    width : 700,
    modal : true,
    buttons : {
      "Add Barcode" : function() {
        addCurrentBarcode();
      },
      "Done" : function() {
        dialog.dialog("close");
        $("#gsheetdiv").show();
      }
    },
    close : function(event, ui) {
      $("#gsheetdiv").show();
    }
  });
}
