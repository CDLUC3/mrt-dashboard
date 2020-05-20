/*
 * Create html blocks to be used by jQuery Dialog widgets controlling the download of
 * presigned object/versions.
 *
 * This class will be initialized on document.ready as a Singleton named: presignDialogs.
 */
var PresignDialogs = function() {
  self = this;

  jQuery("<div id='assembly-dialog'/>")
    .append(
      jQuery("<h1 class='h-title'/>").text("Title: ")
    )
    //.append(jQuery("<div class='assemble-ark'/>").text(key))
    .append(
      jQuery("<div id='assemble-message'/>")
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

    this.resetProgressStatus = function() {
      jQuery("div#assemble-message")
        .empty()
        .append(
          jQuery("<p>Merritt needs time to prepare your download. Your requested object will automatically download when it is ready.</p>")
        )
        .append(
          jQuery("<p>Closing this window will not cancel your download.</p>")
        )
    }

    this.setProgressDownloadedByUser = function() {
      jQuery( "div#assemble-message" )
        .empty()
        .append(
          jQuery("<p/>").text("Downloading " + self.objectAssembler.getDownloadFilename() + ".")
        )
        .append(
          jQuery("<p/>").text("Check your browser download folder. ")
        );

    }

    this.setProgressAssemblyComplete = function() {
      jQuery( "div#assemble-message" )
        .empty()
        .append(jQuery("<p>Your download is available at the following URL:</p>"))
        .append(
          jQuery("<a download/>")
            .on("click", function(){
              self.objectAssembler.assemblyProgress.clearActiveTokenFromDialog();
            })
            .text("Download " + self.objectAssembler.getDownloadFilename())
            .attr("href", self.objectAssembler.presignedUrl)
        );
    }

    this.clearProgress = function() {
      if (this.objectAssembler) {
        if (this.objectAssembler.tokenData) {
          this.objectAssembler.assemblyProgress.setProgressVal(0);
        } else {
          jQuery( "div#progressbar" ).progressbar( "value", 0 );
          var tmsg = "Downloads: None";
          jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
        }
      }
    }

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

    this.updateProgress = function() {
      if (this.objectAssembler) {
        if (this.objectAssembler.tokenData) {
          this.objectAssembler.assemblyProgress.updateProgressLabels();
        } else {
          var tmsg = "Downloads: None";
          jQuery("#downloads").text(tmsg).attr("aria-label", tmsg);
        }
      }
    }

    this.initAssemblyFromTokenData = function(data) {
      if (this.objectAssembler) {
        if (!this.objectAssembler.tokenData) {
          this.objectAssembler.initData(data, data['name'], data['title']);
          this.objectAssembler.assemblyProgress.makeProgressBar();
        }
      }
    }

    this.showCurrentOrContinue = function(data) {
      jQuery("span.presign-title").text(data['title']);
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

    this.assemblyTokenList = new AssemblyTokenList(this);
    this.assemblyTokenList.reviewTokenList();
    this.objectAssembler = new ObjectAssembler(this);
    this.makeErrorDialog = function(title, msg) {
      return jQuery("<div id='dialog'/>")
        .attr("title", title)
        .append(
          jQuery("</p>").text(msg)
        ).dialog();
    }
}
