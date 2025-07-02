import React, { useState, useEffect } from "react";
import "./main.css";
import { Howl } from "howler";
import Footer from "../footer/footer";

export default function Main({ user, onStartGame, onLogout }) {
  const [theme] = useState(
    new Howl({
      src: ["./audio/title_theme.wav"],
      loop: true,
      volume: 0.3,
    })
  );
  const [audioInitialized, setAudioInitialized] = useState(false);

  useEffect(() => {
    window.addEventListener("keydown", (event) => {
      if (["ArrowUp", "ArrowDown"].includes(event.code)) {
        event.preventDefault();
      }
    });
  }, []);

  const handleLogout = () => {
    onLogout();
  };

  const handleSubmit = () => {
    const player = user ? user : undefined;
    console.log('🚀 Starting game with:', { player });
    
    // Inicializar audio solo tras interacción del usuario
    if (!audioInitialized) {
      theme.play();
      setAudioInitialized(true);
    }
    
    theme.pause();
    onStartGame();
  };

  const header = () => {
    return user ? (
      <h1>¡Bienvenido de vuelta {user.username}!</h1>
    ) : (
      <h1>¡Bienvenido a Pac-Man!</h1>
    );
  };

  const buttons = () => {
    return user ? (
      <button className="logout-button" onClick={handleLogout}>
        Cerrar sesión
      </button>
    ) : (
      <p className="auth-message">
        Debes iniciar sesión para jugar
      </p>
    );
  };

  const signupInstructions = () => {
    return user ? (
      <p className="welcome-message">
        ¡Listo para jugar! Usa las teclas direccionales para moverte.
      </p>
    ) : (
      <p className="signup-instructions">
        ¡Crea una cuenta para guardar tu puntuación en el leaderboard!
      </p>
    );
  };

  return (
    <div className="main" id="main">
      {header()}
      {buttons()}
      <br></br>
      <br></br>
      <img
        className="title-gif"
        src="https://media4.giphy.com/media/42rO49pxzaMnK/giphy.gif?cid=790b76116dc1bedf27887938cbe8df55b210b12f842af0e9&rid=giphy.gif&ct=g"
        alt="Pac-Man gif"
      />
      {signupInstructions()}
      <div className="register">
        <button 
          className="play-button" 
          id="play-button" 
          onClick={handleSubmit}
          disabled={!user}
        >
          {user ? 'Jugar' : 'Inicia sesión para jugar'}
        </button>
      </div>
      <p className="name-error" id="name-error"></p>
      <p className="instructions">
        Usa las teclas direccionales para mover a Pac-Man por el tablero mientras evitas a los fantasmas. 
        ¡Recoge un power-up y luego ataca a los fantasmas! Come todos los pellets del tablero para subir de nivel. 
        Presiona ESC para pausar y despausar el juego en cualquier momento. 
        (Para usuarios móviles y tablet, aparecerá un D-pad debajo del tablero para mover a Pac-Man)
      </p>
      <Footer />
    </div>
  );
}
