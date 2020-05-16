jQuery.noConflict();

var objectAssembler;
var presignDialogs;
var assemblyTokenList = new AssemblyTokenList();

function initAssemblyDialogs(data, key, title) {
  objectAssembler = new ObjectAssembler(data, key, title);
  objectAssembler.createDialogs(true);
}

jQuery(document).ready(function(){
  presignDialogs = new PresignDialogs();
  assemblyTokenList.showDownloadLink();

  jQuery("form#button_presign_obj")
  .on("click", function(){ jQuery(this).attr("disabled", true)})
  .on("ajax:success", function(evt, data, status, xhr) {
    var tokenData = assemblyTokenList.addTokenData(data);
    initAssemblyDialogs(tokenData, assemblyTokenList.getTokenKey(), assemblyTokenList.getTokenTitle());
  })
  .on("ajax:error", function( event, xhr, status, error ) {
    var message = error;
    if (xhr.status == 404) {
      message = "Requested object could not be assembled."
    }
    presignDialogs.makeErrorDialog("Object Assembly Error", message);
  })
});
