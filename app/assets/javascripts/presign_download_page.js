jQuery.noConflict();
jQuery(document).ready(function(){
  if (document.location.pathname.match("^/downloads.*")) {
    showTable();
  }

  jQuery("form#button_presign_obj")
  .on("ajax:success", function(evt, data, status, xhr) {
    addTokenData(data);
    initDialogs(data, getTokenKey(), getTokenTitle());
  })
  .on("ajax:error", function( event ) {
    console.log(event);
  })
  .on("ajax:complete", function( event ) {
    //console.log(event);
  });
});
