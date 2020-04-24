$(document).ready(function(){
  var cmd = getCommand();
  var token = getToken();
  if (cmd == "add") {
    addToken(token);
    document.location = "/downloads";
  }
  showTable();
  initDialogs();
});
