/*
 * Create html blocks to be used by jQuery Dialog widgets controlling the download of
 * presigned object/versions.
 *
 * This class will be initialized on document.ready as a Singleton named: presignDialogs.
 */
var PresignDialogs = function() {
  self = this;

  // Create assembly dialog box html
  jQuery("<div id='assembly-dialog-container'/>")
    .append(
      jQuery("<div id='assembly-dialog'/>")
        .append(
          jQuery("<h3 class='h-title'/>").text("Title: ")
        )
        //.append(jQuery("<div class='assemble-ark'/>").text(key))
        .append(
          jQuery("<div id='assemble-message'/>")
        )
        .append(
          jQuery("<div id='progressbar'/>")
        )
        .append(
          jQuery("<label class='progress-label' for='progressbar'/>")
        )
        .hide()
    )
    .appendTo("body");

  // Create Assembly already in progress dialog box html
  jQuery("<div id='download-in-progress-container'/>")
    .append(
      jQuery("<div id='download-in-progress'/>")
        .append(
          jQuery("<h3 class='h-check-title'>An object is already being prepared for download</h3>")
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
    )
    .appendTo("body");

    // Reset the progress bar text to indicate that an assebly has been initiated.
    this.resetProgressStatus = function() {
      if (jQuery("#assembly-dialog").hasClass('ui-dialog-content')) {
        jQuery("#assembly-dialog").dialog("option", "title", "Preparing Object for Download");
      }
      jQuery("div#assemble-message")
        .empty()
        .append(
          jQuery("<p>Merritt needs time to prepare your download. A link to your requested object will be available when it is ready.</p>")
        )
        .append(
          jQuery("<p>Closing this window will not cancel your download.</p>")
        );
      jQuery(".ui-dialog .ui-button:last").focus();
    }

    // Set the status message to indicate that the current assembly is ready for download
    this.setProgressAssemblyComplete = function() {
      if (jQuery("#assembly-dialog").hasClass('ui-dialog-content')) {
        jQuery("#assembly-dialog").dialog("option", "title", "Object is ready for Download");
      }
      jQuery( "div#assemble-message" )
        .empty()
        .append(jQuery("<p>Your download is ready. </p>"))
        .append(
          jQuery("<a class='obj_download' download/>")
            .on("click", function(){
              self.objectAssembler.assemblyProgress.clearActiveTokenFromDialog();
            })
            .text("Download " + self.objectAssembler.getDownloadFilename())
            .attr("href", self.objectAssembler.presignedUrl)
        );
      jQuery(".ui-dialog .ui-button:last").focus();
    }

    // Reset the progress bar text to indicate that the user downloaded an object.
    // This will clear the active assembly token.
    this.setProgressDownloadedByUser = function() {
      if (jQuery("#assembly-dialog").hasClass('ui-dialog-content')) {
        jQuery("#assembly-dialog").dialog("option", "title", "Object download has started");
      }
      jQuery( "div#assemble-message" )
        .empty()
        .append(
          jQuery("<p/>").text("Downloading " + self.objectAssembler.getDownloadFilename() + ".")
        )
        .append(
          jQuery("<p/>").text("Check your browser download folder. ")
        );
      jQuery(".ui-dialog .ui-button:last").focus();
    }

    // Clear the progress bar text and label
    this.clearProgress = function() {
      if (this.objectAssembler) {
        if (this.objectAssembler.tokenData) {
          this.objectAssembler.assemblyProgress.setProgressVal(0);
        } else {
          jQuery( "div#progressbar" ).progressbar( "value", 0 );
          var tmsg = "Downloads: None";
          jQuery("#downloads a").text(tmsg).attr("aria-label", tmsg);
        }
      }
    }

    // Initialize the download button at the top of the screen
    //   - indicate if an assembly is in progress
    //   - indicate if an assembly is complete
    //   - Activate the button to bring up the Assmbly Dialog on button click
    this.initializeDownloadLink = function() {
      jQuery("#downloads")
        .on("click", function(){
          if (self.objectAssembler.tokenData) {
            if ('downloaded' in self.objectAssembler.tokenData) {
              self.makeErrorDialog("No Downloads", "No download assembly is in progress.")
            } else {
              self.objectAssembler.createDialogs(true);
            }
          } else {
            self.makeErrorDialog("No Downloads", "No download assembly is in progress.")
          }
        });
      this.updateProgress();
      if (this.objectAssembler.tokenData) {
        this.objectAssembler.startTimer();
      }
    }

    // Update the progress bar (if initialized)
    // Otherwise, just update the status in the download button
    this.updateProgress = function() {
      if (this.objectAssembler) {
        if (this.objectAssembler.tokenData) {
          this.objectAssembler.assemblyProgress.updateProgressLabels();
        } else {
          var tmsg = "Downloads: None";
          jQuery("#downloads a").text(tmsg).attr("aria-label", tmsg);
        }
      }
    }

    // Initialize the assembly window from data saved with the assembly token
    this.initAssemblyFromTokenData = function(data) {
      if (this.objectAssembler) {
        if (!this.objectAssembler.tokenData) {
          this.objectAssembler.initData(data, data['name'], data['title']);
          this.objectAssembler.assemblyProgress.makeProgressBar();
        }
      }
    }

    // When a download assembly is already in progress or available, prompt the user
    // to confirm that they want to replace the prior assembly with a new assembly.
    this.showCurrentOrContinue = function(data, newTitle, newKey) {
      //if the new request matches the request in progress, show the download status
      if (newKey == data['name']) {
        self.objectAssembler.createDialogs(true);
        return;
      }

      jQuery("span.presign-title").text(data['title']);
      jQuery("h3.h-check-title").text("Title: " + newTitle);
      jQuery("div#download-in-progress")
        .dialog({
        title: "Replace Object Being Prepared for Download?",
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
              self.objectAssembler.createDialogs(true);
            },
            text: 'Continue Previous Download',
            class: 'previous-download'
          },
          {
            click: function() {
              jQuery("form#button_presign_obj").attr("disabled", false);
              self.assemblyTokenList.clearToken();
              jQuery(this).dialog("close");
              jQuery("#button_presign_obj").submit();
            },
            text: 'Download Current Object',
            class: 'current-download'
          }
        ]
      });
    }

    // Show the assembly window for a new token returned from the storage service
    this.showTokenAssemblyProgress = function(data) {
      var tokenData = this.assemblyTokenList.addTokenData(data);
      var key = this.assemblyTokenList.getTokenKey();
      var title = this.assemblyTokenList.getTokenTitle();
      this.objectAssembler.initData(tokenData, key, title);
      this.objectAssembler.createDialogs(true);
    }

    // Singleton objects used to present UI components to the user
    this.assemblyTokenList = new AssemblyTokenList(this);
    // Clear any expired tokens from localStorage
    // Note that this class contains some code that could support multiple downloads in the UI
    this.assemblyTokenList.reviewTokenList();
    this.objectAssembler = new ObjectAssembler(this);

    // Utility method to generate an error dialog
    this.makeErrorDialog = function(title, msg) {
      return jQuery("<div id='error-dialog'/>")
        .attr("title", title)
        .append(
          jQuery("</p>").text(msg)
        ).dialog();
    }

    this.simulateCompletion = function(token, url) {
      this.objectAssembler.assemblyProgress.simulateCompletion(token, url);
    }
}
