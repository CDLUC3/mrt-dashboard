jQuery.noConflict();

var objectAssembler;
var assemblyTokenList = new AssemblyTokenList();

function initAssemblyDialogs(data, key, title) {
  objectAssembler = new ObjectAssembler(data, key, title);
  objectAssembler.createDialogs();
}

jQuery(document).ready(function(){
  if (document.location.pathname.match("^/downloads.*")) {
    assemblyTokenList.showTable();
  }

  jQuery("form#button_presign_obj")
  .on("ajax:success", function(evt, data, status, xhr) {
    assemblyTokenList.addTokenData(data);
    initAssemblyDialogs(data, assemblyTokenList.getTokenKey(), assemblyTokenList.getTokenTitle());
  })
  .on("ajax:error", function( event, xhr, status, error ) {
    var message = error;
    if (xhr.status == 404) {
      message = "Requested object could not be assembled."
    }
    objectAssembler.makeErrorDialog(message);
  })
});
