jQuery(document).ready(function(){
  jQuery("#file").on("change", function(){
    var MAXSZ = Number(jQuery("#upload-limit").val());
    var MAXSZ_DISP = jQuery("#upload-limit-message").val();
    var f = jQuery("#file");
    if (f[0].files) {
      if (f[0].files.length > 0) {
        if (f[0].files[0].size >= MAXSZ) {
          f.val("");
          alert(
            "Individual file uploads to Merritt are limited to " + MAXSZ_DISP + 
            ".\n\nPlease review the Merritt documentation for alternative submission options, or choose a smaller file."
          );
        }
      }      
    }
  });
})
