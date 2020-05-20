/*
 * jQuery Progress Bar for presigned object/version downloads.
 */
var AssemblyProgress = function(assembler, pDialogs) {
  var self = this;
  this.pDialogs = pDialogs;
  this.assemblyTokenList = pDialogs.assemblyTokenList;

  // Create jQuery Progress Bar
  this.makeProgressBar = function() {
    jQuery( "div#progressbar" ).progressbar({
      value: false,
      change: function() {
        self.pDialogs.objectAssembler.assemblyProgress.updateProgressLabels();
      },
      complete: function() {
        //Updat ethe progress bar to indicate that the assembly is complete and ready for download
        self.pDialogs.objectAssembler.assemblyProgress.updateProgressLabels();
        self.assembler.stopTimer();
        self.pDialogs.setProgressAssemblyComplete();
      }
    });
  }
  this.makeProgressBar();
  pDialogs.resetProgressStatus();

  // Update progress bar to reflect that the assembly has been downloaded by the user
  this.clearActiveTokenFromDialog = function() {
    this.pDialogs.setProgressDownloadedByUser();
    jQuery( "div#progressbar,.progress-label" ).hide();
    this.pDialogs.objectAssembler.presignedUrl = "";
    this.pDialogs.objectAssembler.tokenData['downloaded'] = true;
    this.assemblyTokenList.clearToken();
  }

  // Timeout between progress bar udpates
  this.duration = 500;
  // Timeout between token status queries (when 202 received)
  this.durationNotReady = 2000;
  // Assembly Dialog containging this progress bar
  this.assembler = assembler;
  // Unique id for dialog box updates in case 2 timers are initiated
  this.counter = 0;

  // Update the progress bar label and downloads button progress percent
  this.updateProgressLabels = function() {
    var v = jQuery( "div#progressbar" ).progressbar( "value" );
    var msg = this.formatProgressLabel(v);
    jQuery( ".progress-label" ).text( msg ).attr("aria-label", msg);
    var tmsg = "Downloads: " + msg;
    jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
  }

  // formgat progress label percent
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

  // Set the download button display if the progress bar is not visible
  this.setProgressVal = function(v) {
    jQuery( "div#progressbar" ).progressbar( "value", v )
    if (!jQuery( ".progress-label:visible" ).is()){
      var tmsg = "Downloads: " + this.formatProgressLabel(v);
      jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
    }
  }

  // Compute % complete until object has been assembled
  this.progress = function() {
    if (self.counter != self.assembler.counter) {
      return;
    }

    var val = jQuery( "div#progressbar" ).progressbar( "value");

    // If the val is not numeric, the process is being initialized
    if (!jQuery.isNumeric(val)) {
      val = self.assembler.getPercent();
      self.setProgressVal(val);
    }

    // If the percent is already at 100%, no action is needed
    if (val >= 100) {
      return;
    }

    // If the progress is less than 90% complete, set a timer to call this process again
    if (val < 90) {
      val = self.assembler.getPercent();
      self.setProgressVal(val);
      setTimeout( function(){ self.progress() }, self.duration );
      return;
    }

    // If val is 90, call api/presign-obj-by-token to ensure that object is ready
    // If so, an animation will be run to update progress to 100%
    if (val == 90) {
      jQuery.ajax({
        url: "/api/presign-obj-by-token/" + self.assembler.tokenData['token'],
        data: { no_redirect: 1, filename: self.assembler.getDownloadFilename() },
        success: function(data, status, xhr){
          if (xhr.status == 200) {
            // Start animation to update the progress from 90% to 100%
            self.assemblyTokenList.markReady(data['token'], data['url']);
            self.assembler.markReady(data['url']);
            self.setProgressVal(val + 2);
            setTimeout( function(){ self.progress() }, 50 );
          } else {
            // If a 202 is returned, the object is not yet ready.
            // Keep the value at 90% and reset the timer.
            setTimeout( function(){ self.progress() }, self.durationNotReady );
          }
        },
        error: function(xhr, status, err){
          self.pDialogs.makeErrorDialog("Object Assembly Error", "Error in object assembly: " + err);
        },
        dataType: "json",
      });
      return;
    }

    //Increment progress until it is 100%
    val += 2;
    self.setProgressVal(val);
    setTimeout( function(){ self.progress() }, 50 );
  }

}
