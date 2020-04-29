/*
$ = jQuery.noConflict();
$(document).ready(function(){
  if (document.location.pathname.match("^/downloads.*")) {
    var cmd = getCommand();
    var token = getToken();
    if (cmd == "add") {
      addToken(token);
      document.location = "/downloads";
    }
    showTable();
    initDialogs();
  }
});
*/
