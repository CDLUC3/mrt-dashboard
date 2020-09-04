jQuery.noConflict();

// Singleton used for the Presigned Object/Version assembly.
var presignDialogs;

/*
  Dialog Windows
    - #assembly-dialog - used to display the status of an active object assembly.
      - #progressbar - displays the % complete for an assembly
    - #download-in-progress - modal dialog to allow the user to switch the "active" download in the client.
      - For simplicity, the Merritt UI will only support one active assembly at a time.
        There are placeholders in the code to track multiple assembly requests.

  jQuery Controls:
    #downloads - top level button to bring up the presignDialogs.objectAssembler dialog
      - this becomes relevant if the object assembler dialog is closed.
      - this is relevant on a page reload when an assembly is in progress.
    form#button_presign_obj - button to initiate a new object assembly.

  Progress Timer - this is the trickies part of this code.
    The timer is initiated in the following ways:
    - When a new download assembly is initiated
    - On page load when a previous assembly is still in progress.
*/
jQuery(document).ready(function(){
  presignDialogs = new PresignDialogs();
  // Update the "downloads" button at the top of the page to show the status of
  // any outstanding downloads
  presignDialogs.assemblyTokenList.showDownloadLink();

  jQuery("form#button_presign_obj")
  .on("click", function(){ jQuery(this).attr("disabled", true)})
  .on("ajax:success", function(evt, data, status, xhr) {
    // Display the assembly progress window and start a timer to count down until the object is ready
    presignDialogs.showTokenAssemblyProgress(data);
  })
  .on("ajax:error", function( event, xhr, status, error ) {
    var message = error;
    if (xhr.status == 404) {
      message = "Requested object could not be assembled."
    } else if (xhr.status == 408) {
      message = "Request timed out.  Please try your request again later."
    }
    presignDialogs.makeErrorDialog("Object Assembly Error", message);
  });

  jQuery("li.logout a").on("click", function(){
    presignDialogs.assemblyTokenList.clearData();
    return true;
  })
  jQuery("header nav li.dropdown a.expandable, header nav li.dropdown span.expandable")
    .on('keypress', function(e) {
    if (e.which == 32) {
        jQuery(this).parent("li").toggleClass("menuopen");
        return false;
    }
  });
  jQuery("header nav img.expandable")
    .on('keypress', function(e) {
    if (e.which == 32) {
        jQuery("nav.menu > ul").toggle();
        return false;
    }
  });

});
