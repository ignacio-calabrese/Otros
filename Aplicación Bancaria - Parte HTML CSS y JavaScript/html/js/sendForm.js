function sendForm() {
	var http = new XMLHttpRequest();
	var url = "tu_url";
	var signIn = document.getElementById('signIn');

	http.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
	http.open("POST", url, true);

	http.onreadystatechange = function() {
		if(http.readyState == 4 && http.status == 200) { 
			//aqui obtienes la respuesta de tu peticion
			alert(http.responseText);
		}
	}
	http.send(JSON.stringify({email:email, password: password}));
}
