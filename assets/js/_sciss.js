function logIn() {
  var img, img2;
  img = document.getElementById('logImg');
  if (img) {
    img2 = new Image();
	img2.src = "/noises/empty.gif"; // this will prompt user/passwd from server
	img2.onload = function() {
	  document.cookie = 'sciss_loggedin=true;';
	  if (!document.cookie) {
	    alert("Cookies must be accepted from this site!");
	  } else {
	    location.replace(location.href); // reload();
	  }
	};
	img.src = img2.src;
  } else {
	alert("DOM error");
  }
}

