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
    var name = data['name'] == "" ? "No Name" : data['name'];
    var link = jQuery("<a/>").attr("href", href).text(name)
    jQuery("<th/>").appendTo(tr).append(link);
    jQuery("<td/>").appendTo(tr).text(data['title']);
    jQuery("<td/>").appendTo(tr).text(this.formatTime(this.getTime(), data['available']));
    jQuery("<td/>").appendTo(tr).text(this.formatTime(this.getTime(), data['expires']));
    jQuery("<td/>").appendTo(tr).text(data['size']);
    jQuery("<td/>").appendTo(tr).text(data['checkCount']);
    return tr;
  }

  this.getTokenData = function(token) {
    var datastr = localStorage[token];
    if (!datastr) {
      this.clearActiveToken(token);
      return null;
    }
    var data = JSON.parse(datastr);
    var t = this.getTime();
    if (data['expires'] < t) {
      localStorage.removeItem(token);
      this.clearActiveToken(token);
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

    var data = {
      name: key,
      token: token,
      title: title,
      available: d.getTime(),
      expires: d.getTime() + 60 * 60000,
      size: size,
      checkCount: 0
    }
    localStorage[token] = JSON.stringify(data);
    this.showDownloadLink();
    this.setActiveToken(token);
    return data;
  }

  this.setCheckCount = function(token, count) {
    var d = localStorage[token];
    if (d) {
      var data = JSON.parse(d);
      data['checkCount'] = count;
      localStorage[token] = JSON.stringify(data);
    }
  }

  this.showDownloadLink = function() {
    this.checkNoActiveToken();
    jQuery("#downloads")
      .on("click", function(){
        if (objectAssembler) {
          objectAssembler.createDialogs(true);
        }
      });
    this.setDownloadIcon();
  }

  this.clearToken = function() {
    localStorage['active'] = '';
    this.setDownloadIcon();
  }

  this.setDownloadIcon = function() {
    var b = this.checkNoActiveToken();
    var text = b ? "Downloads: None" : "Downloads: Pending";
    jQuery("#downloads").text(text);
    if (!b) {
      if (objectAssembler) {
        objectAssembler.assemblyProgress.progressInit();
        objectAssembler.createDialogs(false);
      }
    }
  }

  this.setActiveToken = function(token) {
    localStorage['active'] = token;
    this.setDownloadIcon();
  }

  this.clearActiveToken = function(token) {
    if (localStorage['active'] == token){
      this.clearToken();
    }
  }

  this.checkNoActiveToken = function() {
    if (!(localStorage['active'])) {
      return true;
    }
    if (localStorage['active'] == '') {
      return true;
    }
    var token = localStorage['active'];
    var data = this.getTokenData(token);
    if (!data) {
      return true;
    }
    if (!objectAssembler) {
      objectAssembler = new ObjectAssembler(data, data['name'], data['title']);
    }
    return false;
  }

  this.checkToken = function() {
    if (this.checkNoActiveToken()) {
      return true;
    }
    var token = localStorage['active'];
    var data = this.getTokenData(token);
    var p1 = jQuery("<p>Your previous download </p>")
      .append(jQuery("<span class='presign-title'>").text(data['title']))
      .append(jQuery("<span> is still in progress. </span>"))
      .append(jQuery("<span>You may only download one object at a time.</span>"));
    var p2 = jQuery("<p>Do you want to download this current object (and cancel the previous download)</p>")
      .append(jQuery("<span> or continue the previous download?</span>"));
    jQuery("<div/>")
      .append(p1)
      .append(p2)
      .dialog({
      title: "Download In Progress",
      autoOpen : true,
      height : 350,
      width : 600,
      maxWidth: jQuery(document).width(),
      modal : true,
      buttons : [
        {
          click: function() {
            jQuery("form#button_presign_obj").attr("disabled", false);
            jQuery(this).dialog("close");
            objectAssembler.createDialogs(true);
          },
          text: 'Continue Previous Download',
          class: 'previous-download'
        },
        {
          click: function() {
            jQuery("form#button_presign_obj").attr("disabled", false);
            assemblyTokenList.clearToken();
            jQuery(this).dialog("close");
            jQuery("#button_presign_obj").submit();
          },
          text: 'Download Current Object',
          class: 'current-download'
        }
      ]
    });
    return false;
  }

  this.getTokenKey = function() {
    return jQuery('h2 span.key').text().trim();
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

var AssemblyProgress = function(assembler) {
  var self = this;
  this.duration = 500;
  this.durationNotReady = 1000;
  this.assembler = assembler;
  this.counter = 0;
  this.checkCounter = 0;

  this.makeProgressBar = function(){
    return jQuery( "div#progressbar" ).progressbar({
      value: false,
      change: function() {
        var msg = jQuery( "div#progressbar" ).progressbar( "value" ) + "%";
        jQuery( ".progress-label" ).text( msg );
        jQuery("#downloads").text("Downloads: " + msg);
      },
      complete: function() {
        self.assembler.dialog.dialog({title: "Download Available"});
        jQuery("button.presign-cancel").hide();
        jQuery( ".progress-label" ).text( "100%" );
        jQuery("#downloads").text("Downloads: 100%");
        jQuery( "div#assemble-message" )
          .empty()
          .append(jQuery("<p>Your download is available at the following URL:</p>"))
          .append(
            jQuery("<a onclick='assemblyTokenList.clearToken()'/>")
              .text("Download " + self.assembler.getDownloadFilename())
              .attr("href", self.assembler.presignedUrl)
          );
      }
    });
  }

  this.progressInit = function() {
    self.progressbar = self.makeProgressBar();
    self.progress();
  }
  this.progress = function() {
    if (self.counter != self.assembler.counter) {
      return;
    }

    var val = self.progressbar.progressbar( "value");
    if (!val) {
      val = self.assembler.getPercent();
      if (val == 90) {
        val = 100;
      }
      self.progressbar.progressbar( "value", val );
    }
    if (val < 90) {
      val = self.assembler.getPercent();
      self.progressbar.progressbar( "value", val );
      self.progressTimer = setTimeout( function(){ self.progress() }, self.duration );
      return;
    }
    if (val >= 100) {
      return;
    }
    if (val == 90) {
      self.checkCounter++;
      jQuery.ajax({
        url: "/api/presign-obj-by-token/" + self.assembler.tokenData['token'],
        data: { no_redirect: 1, filename: self.assembler.getDownloadFilename() },
        success: function(data, status, xhr){
          if (xhr.status == 200) {
            self.assembler.presignedUrl = data['url'];
            self.progressbar.progressbar( "value", val + 2);
            assemblyTokenList.setCheckCount(self.assembler.tokenData['token'], self.checkCounter);
            self.assembler.progressTimer = setTimeout( function(){ self.progress() }, 50 );
          } else {
            self.assembler.progressTimer = setTimeout( function(){ self.progress() }, self.durationNotReady );
          }
        },
        error: function(xhr, status, err){
          this.assembler.makeErrorDialog("Error in object assembly: " + err);
        },
        dataType: "json",
      });
      return;
    }

    val += 2;
    self.progressbar.progressbar( "value", val );
    self.assembler.progressTimer = setTimeout( function(){ self.progress() }, 50 );
  }

}

var ObjectAssembler = function(data, key, title) {
  var self = this;

  this.makeDialogHtml = function(title, key){
    jQuery("div#assembly-dialog").remove();
    var msg = jQuery("<div id='assemble-message'/>")
      .append(jQuery("<p>Merritt needs time to prepare your download. Your requested object will automatically download when it is ready.</p>"))
      .append(jQuery("<p>Closing this window will not cancel your download.</p>"));
    return jQuery("<div id='assembly-dialog'/>")
      .append(jQuery("<h2/>").text("Title: " + title))
      //.append(jQuery("<div class='assemble-ark'/>").text(key))
      .append(jQuery(msg))
      .append(jQuery("<div id='progressbar'/>"))
      .append(jQuery("<div class='progress-label'/>"));
  }

  this.counter = 0;
  this.dialog = this.makeDialogHtml(title, key);
  this.tokenData = data;
  this.ready = new Date(data['available']);
  this.start = new Date();
  this.presignedUrl = "";
  this.assemblyProgress = new AssemblyProgress(this);
  this.progressTimer;

  this.startTimer = function(){
    self.assemblyProgress.counter = self.counter;
    self.assemblyProgress.progressInit();
  }
  this.getDownloadFilename = function() {
    var fname = "object";
    if ('name' in this.tokenData) {
      fname = this.tokenData['name'].replace(/[^A-Za-z0-9]+/g, '_');
    }
    return fname + ".zip";
  }

  this.getPercent = function() {
    //Storage service presumes 20 sec assembly minimum
    //var OFFSET = 20000;
    var OFFSET = 0;
    var d = new Date().getTime();
    var r = this.ready.getTime() - OFFSET;
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

  this.createDialogs = function(show) {
    if (!this.tokenData['token']) {
      this.makeErrorDialog("No download assembly is in progress.")
      return;
    }
    this.dialog.dialog({
      title: "Preparing Download",
      autoOpen : false,
      height : 320,
      width : 600,
      maxWidth: jQuery(document).width(),
      modal : true,
      buttons : [
        {
          click: function() {
            //clearTimeout(self.progressTimer);
            self.dialog.dialog("close");
          },
          text: 'Close',
          class: 'presign presign-close'
        }
      ]
    });
    jQuery("button.presign").show();
    if (show) {
      this.dialog.dialog("open");
    }
    this.startTimer();
  }
}
