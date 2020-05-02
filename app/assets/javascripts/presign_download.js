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
  var tr = jQuery("<tr/>");
  var href = "/downloads/get/"+token;
  if (data['ready']) {
    href += "?available=true";
  }
  var link = jQuery("<a/>").attr("href", href).text(data['name'])
  jQuery("<th/>").appendTo(tr).append(link);
  jQuery("<td/>").appendTo(tr).text(data['title']);
  jQuery("<td/>").appendTo(tr).text(formatTime(getTime(), data['available']));
  jQuery("<td/>").appendTo(tr).text(formatTime(getTime(), data['expires']));
  jQuery("<td/>").appendTo(tr).text(data['size']);
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
  jQuery("table.merritt_downloads tbody tr").remove();
  var tokens = getTokenList();
  var activeTokens = [];
  for (var i=0; i<tokens.length; i++) {
    var token = tokens[i];
    var data = getTokenData(token);
    if (data) {
      activeTokens.push(token)
      jQuery("table.merritt_downloads tbody")
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

function addToken(token, key, title, available, size) {
  if (token == "") {
    return;
  }
  var tokens = getTokenList();
  tokens.push(token);
  localStorage.tokens = tokens.join(",");
  var now = new Date();
  var d = new Date(available);

  data = {
    name: key,
    title: title,
    available: d.getTime(),
    expires: d.getTime() + 60 * 60000,
    size: size
  }
  console.log(data);
  localStorage[token] = JSON.stringify(data);
}

var dialog;

function makeDialogHtml(title){
  return jQuery("<div/>")
    .append(jQuery("<h3/>").text(title))
    .append(jQuery("<p>Merritt needs time to prepare your download. Your requested object will automatically download when it is ready.</p>"))
    .append(jQuery("<p>Closing this window will not cancel your download.</p>"))
    .append(jQuery("<div id='progressbar'/>"))
    .append(jQuery("<div class='progress-label'/>"))
    .append(jQuery("<div id='progress-download'/>"));
}

function initDialogs(data, key, title) {
  dialog = makeDialogHtml(title);
  dialog.dialog({
    title: "Preparing Download: " + key,
    autoOpen : true,
    height : 450,
    width : 600,
    position: {
      my: "center",
      at: "center",
      of: window
    },
    modal : true,
    buttons : {
      "Option 1" : function() {
        var x = 0;
      },
      "Done" : function() {
        dialog.dialog("close");
      }
    },
    close : function(event, ui) {
    }
  });

  var progressbar = jQuery( "div#progressbar" );
  var progressLabel = jQuery( ".progress-label" );
  var progressDownload = jQuery( "div#progress-download" );
  var progressTimer = setTimeout( progress, 100 );

  function progress() {
    var val = jQuery( "div#progressbar" ).progressbar( "value" ) || 0;
    jQuery( "div#progressbar" ).progressbar( "value", val + 1 );
    if ( val < 100 ) {
      progressTimer = setTimeout( progress, 100 );
    }
  }

  progressbar.progressbar({
    value: false,
    change: function() {
      progressLabel.text( "Current Progress: " + progressbar.progressbar( "value" ) + "%" );
    },
    complete: function() {
      progressLabel.text( "Current Progress: Ready!" );
      progressDownload
        .empty()
        .append(
          jQuery("<a>Download</a>")
            .attr("href", "/api/presign-obj-by-token/" + data['token'])
        );
    }
  });

}

function getTokenKey() {
  return jQuery('h2.key').text();
}

function getTokenTitle() {
  return jQuery('h3.object-title span.title').text();
}

function addTokenData(data) {
  addToken(
    data['token'],
    getTokenKey(),
    getTokenTitle(),
    data['anticipated-availability-time'],
    data['cloud-content-byte']
  );
}
