var ObjectAssembler = function(pDialogs) {
  var self = this;

  // Set the title field for the Assembly Dialog
  this.setDialogTitleKey = function(key, title) {
    jQuery("h1.h-title").text("Title: " + title);
  }

  // Unique counter to prevent the assembly dialog from responding to obsolete timer events
  this.counter = 0;

  // The data properties for the active token that is being assembled
  this.tokenData = null;

  // Date when an assembly is anticipated to be complete
  this.ready = new Date();

  /// Date when the assembly window was initiated (used for progress calculation)
  this.start = new Date();

  // Presigned URL associated with the current token
  this.presignedUrl = "";

  // Create progress bar widget that will be updated by a timer
  this.assemblyProgress = new AssemblyProgress(this, pDialogs);

  this.timerRunning = false;

  // Start a timer to update the progress dialog which is updated by the progress() method
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

  // Set data properties for the current token
  this.setTokenData = function(data) {
    this.tokenData = data;
    this.ready = new Date(data['available']);
    this.start = new Date();
    if (data['url']) {
      this.presignedUrl = data['url'];
    }
  }

  // Mark the UI to know that the assembly is complete and should render 100% progress
  this.markReady = function(url) {
    if (this.tokenData) {
      this.tokenData['url'] = url;
      this.presignedUrl = url;
    }
  }

  // Initialize the assembly window from a data object and title information from the UI screen
  this.initData = function(data, key, title) {
    this.setTokenData(data);
    this.setDialogTitleKey(key, title);
  }

  // Note that a timer is complete
  this.stopTimer = function(){
    self.timerRunning = false;
  }

  // Compute the filename to assign to a download object
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

  // Calculate percent complete
  //  - 0% At assembly window create
  //  - 90% At anticipated object availability
  //  - 92-98% animated progress status once the storage service confirms that the token is ready
  //  - 100% assembly complete and presigned URL stored in the UI
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

  // Create the jQuery Dialog for the assembly modal dialog
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
