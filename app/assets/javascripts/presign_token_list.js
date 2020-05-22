/*
 * This class manages a list of tokens for presigned object/version downloads in Browser localStorage.
 *
 * This class will be initialized on document.ready as presignDialogs.assemblyTokenList.
 *
 * localStorage {
 *   active: name, //name of the active token,
 *   tokens: list, //comma separated list of tokens that have not expired,
 *   *token*: {
 *     name: key,       // ark + [version] string
 *     token: token,    // token name
 *     title: title,    // displayable time
 *     available: time, // time as long int when the object should be available
 *     expires: time,   // time as long int when the token will expire (by definition of the client)
 *     size: size,      // uncompressed size of object to be downloaded
 *     ready: boolean  // indicates if object/version should be ready
 *   }
 * }
 */
var AssemblyTokenList = function(pDialogs) {
  var self = this;
  this.pDialogs = pDialogs;

  // Clear all tokens in localStorage
  this.clearData = function() {
    localStorage.setItem('tokens', "");
  }

  // The data associated with a specific token is stored as a JSON object.
  // Purge the token from local storage if the expires time is in the past.
  // Set the 'ready' status for the token
  this.getTokenData = function(token) {
    var datastr = localStorage.getItem(token);
    if (!datastr) {
      this.clearActiveToken(token);
      return null;
    }
    var data = JSON.parse(datastr);
    var t = this.getTime();
    if (data['expires'] < t) {
      localStorage.removeItem(token);
      this.clearActiveToken(token);
      return null;
    }
    data['ready'] = (data['available'] <= t);
    return data;
  }

  // Get the list of available tokens as an array.
  // This is designed to support multiple active downloads in the client.
  // Currently, only a single download is supported.
  this.getTokenList = function(){
    if (localStorage.getItem('tokens') == null || localStorage.getItem('tokens') == "") {
      return [];
    }
    return localStorage.getItem('tokens').split(",");
  }

  this.reviewTokenList = function() {
    var tokens = this.getTokenList();
    var activeTokens = [];
    for(var i=0; i<tokens.length; i++) {
      //clear data for expired tokens
      if (this.getTokenData(tokens[i])){
        activeTokens.push(tokens[i]);
      }
    }
    this.saveTokenList(activeTokens);
  }


  // Format time duration as an easy to read string.
  this.formatTime = function(t, comp) {
    var diff = comp - t;
    if (diff < 100) return 'Now';
    if (diff > 60000) return '' + Math.round(diff / 60000) + ' min';
    return '' + Math.round(diff / 1000) + ' sec';
  }

  // Get the current time as a long integer
  this.getTime = function() {
    return new Date().getTime();
  }

  this.saveTokenList = function(tokens) {
    localStorage.setItem('tokens', tokens.join(","));
  }

  // Add a new token to local storage based on data returned from the Storage service
  // Currently, the expires time is defaulting to 20 hours after anticipated availability
  this.addToken = function(token, key, title, available, size) {
    if (token == "") {
      return;
    }
    var tokens = this.getTokenList();
    tokens.push(token);
    this.saveTokenList(tokens);
    var now = new Date();
    var d = new Date(available);

    var data = {
      name: key,
      token: token,
      title: title,
      available: d.getTime(),
      expires: d.getTime() + 20 * 60 * 60000,
      size: size
    }
    this.saveToken(token, data);
    this.showDownloadLink();
    this.setActiveToken(token);
    return data;
  }

  // Save token data to localStorage
  this.saveToken = function(token, data) {
    localStorage.setItem(token, JSON.stringify(data));
  }

  // Update url in local storage
  this.markReady = function(token, url) {
    var data = this.getTokenData(token);
    if (data) {
      data['url'] = url;
      this.saveToken(token, data);
    }
  }

  // Decorate and bind event to the #downloads button based on the status of an active download token
  // If an active download is in progress, start the progress timer.
  this.showDownloadLink = function() {
    this.checkNoActiveToken();
    this.pDialogs.initializeDownloadLink();
  }

  //Clear the active #download button to indicate that no download assembly is in progress.
  this.clearToken = function() {
    localStorage.setItem('active', '');
    this.pDialogs.clearProgress();
    this.setDownloadIcon();
  }

  // Decorate the #download button and the .download-label status based on assembly progress.
  this.setDownloadIcon = function() {
    var b = this.checkNoActiveToken();
    this.pDialogs.updateProgress();
  }

  // Set the active token for an assembly download
  this.setActiveToken = function(token) {
    localStorage.setItem('active', token);
    this.setDownloadIcon();
  }

  // Clear the data for an assembly download token if it is the current assembly in progress.
  this.clearActiveToken = function(token) {
    if (localStorage.getItem('active') == token){
      this.clearToken();
    }
  }

  // Test to see that no active token exists
  //  or if it exists, test to see if it has expired.
  // If an active token does exist, construct update the object assembly dialog
  // to reflect the data for the current token.
  this.checkNoActiveToken = function() {
    if (!(localStorage.getItem('active'))) {
      return true;
    }
    if (localStorage.getItem('active') == '') {
      return true;
    }
    var token = localStorage.getItem('active');
    var data = this.getTokenData(token);
    if (!data) {
      return true;
    }
    // If an active assembly is in progress, initialize the assembly dialog
    this.pDialogs.initAssemblyFromTokenData(data);
    return false;
  }

  // Check if an active download is in progress before initiating a new download.
  this.checkToken = function() {
    if (this.checkNoActiveToken()) {
      return true;
    }
    var token = localStorage.getItem('active');
    var data = this.getTokenData(token);

    // Presetn dialog box to user to see if they want to resume current assembly or continue with request
    this.pDialogs.showCurrentOrContinue(data, this.getTokenTitle(), this.getTokenKey());
    return false;
  }

  // Get the key (ark/version) for an object/version assembly using jQuery selectors
  this.getTokenKey = function() {
    return jQuery('h2 span.key').text().trim();
  }

  // Get the title for an object/version assembly using jQuery selectors
  this.getTokenTitle = function() {
    var title = jQuery('h3.object-title span.title').text();
    var vtitle = jQuery('td.version-label').text();
    if (vtitle != '') {
      title += " (version " + vtitle + ")";
    }
    return title;
  }

  // Convert the return JSON data from the storage service into a token data record.
  this.addTokenData = function(data) {
    return this.addToken(
      data['token'],
      this.getTokenKey(),
      this.getTokenTitle(),
      data['anticipated-availability-time'],
      data['cloud-content-byte']
    );
  }
}
