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
      clearActiveToken(token);
      return null;
    }
    var data = JSON.parse(datastr);
    var t = this.getTime();
    if (data['expires'] < t) {
      localStorage.removeItem(token);
      clearActiveToken(token);
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
      token: token,
      title: title,
      available: d.getTime(),
      expires: d.getTime() + 60 * 60000,
      size: size
    }
    localStorage[token] = JSON.stringify(data);
    this.showDownloadLink();
    localStorage['active'] = token;
    return data;
  }

  this.showDownloadLink = function() {
    jQuery("#downloads")
      .on("click", function(){
        if (objectAssembler) {
          objectAssembler.createDialogs()
        }
      });
  }

  this.clearToken = function() {
    localStorage['active'] = '';
  }

  this.clearActiveToken = function(token) {
    if (localStorage['active'] == token){
      this.clearToken();
    }
  }

  this.checkToken = function() {
    if (!(localStorage['active'])) {
      return true;
    }
    if (localStorage['active'] == '') {
      return true;
    }
    var token = localStorage['active'];
    data = this.getTokenData(token);
    if (!data) {
      return true;
    }
    if (!objectAssembler) {
      return true;
    }
    var p1 = jQuery("<p>Your previous download </p>")
      .append(jQuery("<span class='presign-title'>").text(data['title']))
      .append(jQuery("<span> is still in progress. </span>"))
      .append(jQuery("<span>You may only download one object at a time.</span>"));
    var p2 = jQuery("<p>Do you want to download this current object (and cancel the previous download)</p>")
      .append(jQuery("<span> or continue the previous download?</span>"));
    var inProg = jQuery("<div/>")
      .append(p1)
      .append(p2)
      .dialog({
      title: "Download In Progress",
      autoOpen : true,
      height : 350,
      width : 600,
      modal : true,
      buttons : [
        {
          click: function() {
            jQuery(this).dialog("close");
            objectAssembler.createDialogs();
          },
          text: 'Continue Previous Download'
        },
        {
          click: function() {
            assemblyTokenList.clearToken();
            jQuery(this).dialog("close");
            jQuery("#button_presign_obj").submit();
          },
          text: 'Download Current Object'
        }
      ]
    });
    return false;
  }

  this.getTokenKey = function() {
    return jQuery('h2.key').text();
  }

  this.getTokenTitle = function() {
    return jQuery('h3.object-title span.title').text();
  }

  this.addTokenData = function(data) {
    return this.addToken(
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
    var msg = jQuery("<div id='assemble-message'/>")
      .append(jQuery("<p>Merritt needs time to prepare your download. Your requested object will automatically download when it is ready.</p>"))
      .append(jQuery("<p>Closing this window will not cancel your download.</p>"));
    return jQuery("<div id='assembly-dialog'/>")
      .append(jQuery("<h3/>").text(title))
      .append(jQuery("<div class='assemble-ark'/>").text(key))
      .append(jQuery(msg))
      .append(jQuery("<div id='progressbar'/>"))
      .append(jQuery("<div class='progress-label'/>"));
  }

  this.dialog = this.makeDialogHtml(title, key);
  this.tokenData = data;
  this.ready = new Date(data['available']);
  this.start = new Date();
  this.presignedUrl = "";

  this.getPercent = function() {
    var d = new Date().getTime();
    var r = this.ready.getTime();
    var s = this.start.getTime();
    if (d >= r) {
      return 90;
    }
    if (r == s) {
      return 90;
    }
    var pct = Math.round((d - s) * 90 / (r - s));
    return pct;
  }

  this.getDuration = function() {
    var d = new Date().getTime();
    var r = this.ready.getTime();
    return "" + (r - d) + "ms";
  }

  this.makeErrorDialog = function(msg) {
    return jQuery("<div id='dialog' title='Object Assembly Error'/>")
      .append(jQuery("</p>").text(msg)).dialog();
  }

  this.createDialogs = function() {
    jQuery("button.presign").show();
    this.dialog.dialog({
      title: "Assembling Object for Download",
      autoOpen : true,
      height : 350,
      width : 600,
      modal : true,
      buttons : [
        {
          click: function() {
            assemblyTokenList.clearToken();
            clearTimeout(progressTimer);
            jQuery(this).dialog("close");
          },
          text: 'Cancel Download',
          class: 'presign presign-cancel'
        },
        {
          click: function() {
            clearTimeout(progressTimer);
            jQuery(this).dialog("close");
          },
          text: 'Close',
          class: 'presign presign-close'
        }
      ]
    });

    var progressbar = jQuery( "div#progressbar" );
    var progressLabel = jQuery( ".progress-label" );
    var progressMessage = jQuery( "div#assemble-message" );
    var progressTimer = setTimeout( progress, 250 );

    function progress() {
      var val = self.getPercent();
      if (self.presignedUrl != "") {
        val = 100;
      }
      jQuery( "div#progressbar" ).progressbar( "value", val );
      if ( val == 100 ) {
        return;
      } else if ( val < 90 ) {
        progressTimer = setTimeout( progress, 250 );
        return;
      }
      jQuery.ajax({
        url: "/api/presign-obj-by-token/"+data['token'],
        data: { no_redirect: 1 },
        success: function(data, status, xhr){
          if (xhr.status == 200) {
            self.presignedUrl = data['url'];
            progressTimer = setTimeout( progress, 0 );
          } else {
            progressTimer = setTimeout( progress, 250 );
          }
        },
        error: function(xhr, status, err){
          alert(err);
        },
        dataType: "json",
      });
    }

    progressbar.progressbar({
      value: false,
      change: function() {
        progressLabel.text( "Current Progress: " + progressbar.progressbar( "value" ) + "%");
      },
      complete: function() {
        jQuery("button.presign-cancel").hide();
        progressLabel.text( "Current Progress: Ready!" );
        progressMessage
          .empty()
          .append(jQuery("<p>Your download is available at the following URL:</p>"))
          .append(
            jQuery("<a onclick='assemblyTokenList.clearToken()'>Download</a>")
              .attr("href", self.presignedUrl)
          );
      }
    });

  }
}
