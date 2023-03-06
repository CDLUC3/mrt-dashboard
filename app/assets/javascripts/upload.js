jQuery(document).ready(function(){
  jQuery("#file").on("change", function(){
    var MAXSZ = 1 * 1000000;
    var MAXSZ_DISP = '1 MB';
    var f = $(this);
    if (f.files) {
      if (f.files.length > 0) {
        if (f.files[0].size >= MAXSZ) {
          jQuery(this).val("");
          alert(
            "Individual file uploads to Merritt are limited to " + MAXSZ_DISP + 
            ".\n\nPlease review the Merritt documentation for alternative submission options." +
            ".\n\nPlease choose a different file."
          );
        }
      }      
    }
  });
})
