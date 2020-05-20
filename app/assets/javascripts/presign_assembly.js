var ObjectAssembler = function(pDialogs) {
  var self = this;

  this.setDialogTitleKey = function(key, title) {
    jQuery("h1.h-title").text("Title: " + title);
  }

  this.counter = 0;
  this.tokenData = null;
  this.ready = new Date();
  this.start = new Date();
  this.presignedUrl = "";
  this.assemblyProgress = new AssemblyProgress(this, pDialogs);

  this.timerRunning = false;
  this.startTimer = function(){
    if (!self.timerRunning) {
      self.counter++;
      self.timerRunning = true;
      self.assemblyProgress.counter = self.counter;
      presignDialogs.resetProgressStatus();
      self.assemblyProgress.progress();
      jQuery( "div#progressbar,.progress-label" ).show();
    }
  }

  this.setTokenData = function(data) {
    this.tokenData = data;
    this.ready = new Date(data['available']);
    this.start = new Date();
    if (data['url']) {
      this.presignedUrl = data['url'];
    }
  }

  this.initData = function(data, key, title) {
    this.setTokenData(data);
    this.setDialogTitleKey(key, title);
  }

  this.stopTimer = function(){
    self.timerRunning = false;
  }

  this.getDownloadFilename = function() {
    if (!this.tokenData) {
      return "not_applicable";
    }
    var fname = "object";
    if ('name' in this.tokenData) {
      fname = this.tokenData['name'].replace(/[^A-Za-z0-9]+/g, '_');
    }
    return fname + ".zip";
  }

  this.getPercent = function() {
    if (!this.tokenData) {
      return 0;
    }

    // Check if a presigned URL has already been set for the item
    if ("url" in this.tokenData) {
      return 100;
    }

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
    if (!this.tokenData) {
      return "not_applicable";
    }
    var d = new Date().getTime();
    var r = this.ready.getTime();
    return "" + (r - d) + "ms";
  }

  this.createDialogs = function(show) {
    if (!this.tokenData) {
      return;
    }
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
