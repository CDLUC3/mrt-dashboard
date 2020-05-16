
var PresignDialogs = function() {
  this.makeErrorDialog = function(title, msg) {
    return jQuery("<div id='dialog'/>")
      .attr("title", title)
      .append(
        jQuery("</p>").text(msg)
      ).dialog();
  }

  jQuery("<div id='assembly-dialog'/>")
    .append(
      jQuery("<h1 class='h-title'/>").text("Title: ")
    )
    //.append(jQuery("<div class='assemble-ark'/>").text(key))
    .append(
      jQuery("<div id='assemble-message'/>")
        .append(
          jQuery("<p>Merritt needs time to prepare your download. Your requested object will automatically download when it is ready.</p>")
        )
        .append(
          jQuery("<p>Closing this window will not cancel your download.</p>")
        )
    )
    .append(
      jQuery("<div id='progressbar'/>")
    )
    .append(
      jQuery("<div class='progress-label'/>")
    )
    .hide()
    .appendTo("body");

  jQuery("<div id='download-in-progress'/>")
    .append(
      jQuery("<h1 class='h-title'>Download in Progress</h1>")
    )
    .append(
      jQuery("<p>Your previous download </p>")
        .append(
          jQuery("<span class='presign-title'>")
        )
        .append(
          jQuery("<span> is still in progress. </span>")
        )
        .append(
          jQuery("<span>You may only download one object at a time.</span>")
        )
    )
    .append(
      jQuery("<p>Do you want to download this current object (and cancel the previous download)</p>")
        .append(
          jQuery("<span> or continue the previous download?</span>")
        )
    )
    .hide()
    .appendTo("body");
}

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
    localStorage.setItem('tokens', "");
  }

  this.getTokenData = function(token) {
    var datastr = localStorage.getItem(token);
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

  this.getTokenList = function(){
    if (localStorage.getItem('tokens') == null || localStorage.getItem('tokens') == "") {
      return [];
    }
    return localStorage.getItem('tokens').split(",");
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
    localStorage.setItem('tokens', tokens.join(","));
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
    localStorage.setItem(token, JSON.stringify(data));
    this.showDownloadLink();
    this.setActiveToken(token);
    return data;
  }

  this.setCheckCount = function(token, count) {
    var d = localStorage.getItem(token);
    if (d) {
      var data = JSON.parse(d);
      data['checkCount'] = count;
      localStorage.setItem(token, JSON.stringify(data));
    }
  }

  this.showDownloadLink = function() {
    this.checkNoActiveToken();
    jQuery("#downloads")
      .on("click", function(){
        if (objectAssembler) {
          if ('downloaded' in objectAssembler.tokenData) {
            presignDialogs.makeErrorDialog("No Downloads", "No download assembly is in progress.")
          } else {
            objectAssembler.createDialogs(true);
          }
        } else {
          presignDialogs.makeErrorDialog("No Downloads", "No download assembly is in progress.")
        }
      });
    this.setDownloadIcon();
    if (objectAssembler) {
      objectAssembler.startTimer();
    }
  }

  this.clearToken = function() {
    localStorage.setItem('active', '');
    if (objectAssembler) {
      objectAssembler.assemblyProgress.setProgressVal(0);
    } else {
      jQuery( "div#progressbar" ).progressbar( "value", 0 );
      var tmsg = "Downloads: None**";
      jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
    }
    this.setDownloadIcon();
  }

  this.setDownloadIcon = function() {
    var b = this.checkNoActiveToken();
    if (objectAssembler) {
      objectAssembler.assemblyProgress.updateProgressLabels();
    } else {
      var tmsg = "Downloads: None*";
      jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
    }
  }

  this.setActiveToken = function(token) {
    localStorage.setItem('active', token);
    this.setDownloadIcon();
  }

  this.clearActiveToken = function(token) {
    if (localStorage.getItem('active') == token){
      this.clearToken();
    }
  }

  this.checkNoActiveToken = function() {
    if (!(localStorage.getItem('active'))) {
      return true;
    }
    if (localStorage.getItem('active') == '') {
      return true;
    }
    var token = localStorage.getItem('active');
    var data = this.getTokenData(token);
    if (!data) {
      return true;
    }
    if (!objectAssembler) {
      objectAssembler = new ObjectAssembler(data, data['name'], data['title']);
      objectAssembler.assemblyProgress.makeProgressBar();
    }
    return false;
  }

  this.checkToken = function() {
    if (this.checkNoActiveToken()) {
      return true;
    }
    var token = localStorage.getItem('active');
    var data = this.getTokenData(token);

    jQuery("#presign-title").text(data['title']);
    jQuery("div#download-in-progress")
      .dialog({
      title: "Download In Progress",
      autoOpen : true,
      height : 350,
      width : jQuery(document).width() < 600 ? jQuery(document).width() * .9 : 600,
      modal : true,
      classes: {
        "ui-dialog": "highlight download-in-progress"
      },
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
  this.makeProgressBar = function() {
    jQuery( "div#progressbar" ).progressbar({
      value: false,
      change: function() {
        objectAssembler.assemblyProgress.updateProgressLabels();
      },
      complete: function() {
        objectAssembler.assemblyProgress.updateProgressLabels();
        self.assembler.stopTimer();
        jQuery( "div#assemble-message" )
          .empty()
          .append(jQuery("<p>Your download is available at the following URL:</p>"))
          .append(
            jQuery("<a download/>")
              .on("click", function(){
                objectAssembler.assemblyProgress.clearActiveTokenFromDialog();
              })
              .text("Download " + objectAssembler.getDownloadFilename())
              .attr("href", objectAssembler.presignedUrl)
          );
      }
    });
  }
  this.makeProgressBar();

  this.clearActiveTokenFromDialog = function() {
    jQuery( "div#assemble-message" )
      .empty()
      .append(
        jQuery("<p/>").text("Downloading " + objectAssembler.getDownloadFilename() + ".")
      )
      .append(
        jQuery("<p/>").text("Check your browser download folder. ")
      );
    jQuery( "div#progressbar,.progress-label" ).hide();
    objectAssembler.presignedUrl = "";
    objectAssembler.tokenData['downloaded'] = true;
    assemblyTokenList.clearToken();
  }

  this.duration = 500;
  this.durationNotReady = 2000;
  this.assembler = assembler;
  this.counter = 0;
  this.checkCounter = 0;

  this.updateProgressLabels = function() {
    var v = jQuery( "div#progressbar" ).progressbar( "value" );
    var msg = this.formatProgressLabel(v);
    jQuery( ".progress-label" ).text( msg ).attr("aria-label", msg);
    var tmsg = "Downloads: " + msg;
    jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
  }

  this.formatProgressLabel = function(v) {
    var msg = v + "%";
    if (!jQuery.isNumeric(v)) {
      msg = "None";
    } else if (v == 0) {
      msg = "None";
    } else if (v == 100) {
      msg = "Available";
    } else {
      msg = v + "%";
    }
    return msg;
  }

  this.setProgressVal = function(v) {
    jQuery( "div#progressbar" ).progressbar( "value", v )
    if (!jQuery( ".progress-label:visible" ).is()){
      var tmsg = "Downloads: " + this.formatProgressLabel(v);
      jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
    }
  }

  this.progress = function() {
    if (self.counter != self.assembler.counter) {
      return;
    }

    var val = jQuery( "div#progressbar" ).progressbar( "value");
    if (!jQuery.isNumeric(val)) {
      val = self.assembler.getPercent();
      if (val == 90) {
        val = 100;
      }
      self.setProgressVal(val);
    }
    if (val < 90) {
      val = self.assembler.getPercent();
      self.setProgressVal(val);
      setTimeout( function(){ self.progress() }, self.duration );
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
            self.setProgressVal(val + 2);
            assemblyTokenList.setCheckCount(self.assembler.tokenData['token'], self.checkCounter);
            setTimeout( function(){ self.progress() }, 50 );
          } else {
            setTimeout( function(){ self.progress() }, self.durationNotReady );
          }
        },
        error: function(xhr, status, err){
          presignDialogs.makeErrorDialog("Object Assembly Error", "Error in object assembly: " + err);
        },
        dataType: "json",
      });
      return;
    }

    val += 2;
    self.setProgressVal(val);
    setTimeout( function(){ self.progress() }, 50 );
  }

}

var ObjectAssembler = function(data, key, title) {
  var self = this;

  this.setDialogTitleKey = function(key, title) {
    jQuery("h1.h-title").text("Title: " + title);
  }

  this.counter = 0;
  this.setDialogTitleKey(key, title);
  this.tokenData = data;
  this.ready = new Date(data['available']);
  this.start = new Date();
  this.presignedUrl = "";
  this.assemblyProgress = new AssemblyProgress(this);

  this.timerRunning = false;
  this.startTimer = function(){
    if (!self.timerRunning) {
      self.timerRunning = true;
      self.assemblyProgress.counter = self.counter;
      self.assemblyProgress.progress();
      jQuery( "div#progressbar,.progress-label" ).show();
    }
  }
  this.stopTimer = function(){
    self.timerRunning = false;
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

  this.createDialogs = function(show) {
    if (!this.tokenData['token']) {
      presignDialogs.makeErrorDialog("No downloads", "No download assembly is in progress.")
      return;
    }
    self.assemblyProgress.makeProgressBar();
    jQuery("div#assembly-dialog").dialog({
      title: "Preparing Download",
      autoOpen : false,
      height : 320,
      width : jQuery(document).width() < 600 ? jQuery(document).width() * .9 : 600,
      modal : true,
      buttons : [
        {
          click: function() {
            jQuery(this).dialog("close");
          },
          text: 'Close',
          class: 'presign presign-close'
        }
      ]
    });
    jQuery("button.presign").show();
    if (show) {
      jQuery("div#assembly-dialog").dialog("open");
    }
    self.startTimer();
  }
}
