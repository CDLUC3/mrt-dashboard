var AssemblyTokenList = function() {
  var self = this;
  this.getToken = function() {
    var loc = document.location.pathname;
    var arr = loc.split("/");
    if (arr.length > 1) {
      return arr[arr.length - 1];
    }
    return "";
  }

  this.clearData = function() {
    localStorage.tokens = "";
    this.showTable();
  }

  this.createRow = function(token, data) {
    var t = this.getTime();
    var tr = jQuery("<tr/>");
    var href = "/downloads/get/"+token;
    if (data['ready']) {
      href += "?available=true";
    }
    var link = jQuery("<a/>").attr("href", href).text(data['name'])
    jQuery("<th/>").appendTo(tr).append(link);
    jQuery("<td/>").appendTo(tr).text(data['title']);
    jQuery("<td/>").appendTo(tr).text(this.formatTime(this.getTime(), data['available']));
    jQuery("<td/>").appendTo(tr).text(this.formatTime(this.getTime(), data['expires']));
    jQuery("<td/>").appendTo(tr).text(data['size']);
    return tr;
  }

  this.getTokenData = function(token) {
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

  this.showTable = function() {
    jQuery("table.merritt_downloads tbody tr").remove();
    var tokens = this.getTokenList();
    var activeTokens = [];
    for (var i=0; i<tokens.length; i++) {
      var token = tokens[i];
      var data = this.getTokenData(token);
      if (data) {
        activeTokens.push(token)
        jQuery("table.merritt_downloads tbody")
          .append(this.createRow(token, data));
      }
    }
  }

  this.getTokenList = function(){
    if (localStorage.tokens == null || localStorage.tokens == "") {
      return [];
    }
    return localStorage.tokens.split(",");
  }

  this.formatTime = function(t, comp) {
    var diff = comp - t;
    if (diff < 100) return 'Now';
    if (diff > 60000) return '' + Math.round(diff / 60000) + ' min';
    return '' + Math.round(diff / 1000) + ' sec';
  }

  this.getTime = function() {
    return new Date().getTime();
  }

  this.addToken = function(token, key, title, available, size) {
    if (token == "") {
      return;
    }
    var tokens = this.getTokenList();
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
    localStorage[token] = JSON.stringify(data);
  }

  this.getTokenKey = function() {
    return jQuery('h2.key').text();
  }

  this.getTokenTitle = function() {
    return jQuery('h3.object-title span.title').text();
  }

  this.addTokenData = function(data) {
    this.addToken(
      data['token'],
      this.getTokenKey(),
      this.getTokenTitle(),
      data['anticipated-availability-time'],
      data['cloud-content-byte']
    );
  }
}

var ObjectAssembler = function(data, key, title) {
  var self = this;

  this.makeDialogHtml = function(title, key){
    return jQuery("<div/>")
      .append(jQuery("<h3/>").text(title))
      .append(jQuery("<div class='assemble-ark'/>").text(key))
      .append(jQuery("<p>Merritt needs time to prepare your download. Your requested object will automatically download when it is ready.</p>"))
      .append(jQuery("<p>Closing this window will not cancel your download.</p>"))
      .append(jQuery("<div id='progressbar'/>"))
      .append(jQuery("<div class='progress-label'/>"))
      .append(jQuery("<div id='progress-download'/>"));
  }

  this.dialog = this.makeDialogHtml(title, key);
  this.tokenData = data;
  this.ready = new Date(data['available']);
  this.start = new Date();

  this.makeErrorDialog = function(msg) {
    return jQuery("<div id='dialog' title='Object Assembly Error'/>")
      .append(jQuery("</p>").text(msg)).dialog();
  }

  this.createDialogs = function() {
    this.dialog.dialog({
      title: "Assembling Object for Download",
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
          this.dialog.dialog("close");
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
}
