const http = require('http');

// Función simple que devuelve el estado de salud
function getHealthStatus() {
  return {
    status: "OK",
    timestamp: new Date().toISOString(),
    message: "¡La aplicación está ON FIREEEE! 🚀"
  };
}

const server = http.createServer((req, res) => {
  // Si la petición es para /health, respondemos con el JSON de salud
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(getHealthStatus()));
  } 
  // Si no, mostramos la página principal
  else {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end('<h1>¡Hola Mundo DevOps desde Docker Compose! 🚀</h1>');
  }
});

server.listen(3000, '0.0.0.0', () => {
  console.log('Servidor corriendo en el puerto 3000, con endpoint /health listo.');
});
