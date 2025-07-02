import React, { useState, useEffect } from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import axios from "axios";
import "./App.css";
import Main from "./components/main/main";
import Auth from "./components/Auth/Auth";
import GameResults from "./components/GameResults/GameResults";
import Game from "./components/game/game";


const authUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/auth`
  : "http://localhost:8080/auth";

export default function App() {
  const [user, setUser] = useState();
  const [gameResults, setGameResults] = useState(null);
  const [gameActive, setGameActive] = useState(false);

  useEffect(() => {
    if (localStorage.getItem("token")) {
      axios
        .get(authUrl, {
          headers: {
            Authorization: localStorage.getItem("token"),
          },
        })
        .then((res) => {
          setUser(res.data.user);
        })
        .catch(() => {
          // Si el token es inválido, lo removemos
          localStorage.removeItem("token");
        });
    }
  }, []);

  const handleAuth = (userData) => {
    setUser(userData);
  };

  const handleGameEnd = (results) => {
    console.log('🏁 handleGameEnd called with:', results);
    setGameResults(results);
    setGameActive(false);
  };

  const handleStartGame = () => {
    setGameActive(true);
  };

  const handleBackToGame = () => {
    setGameResults(null);
  };

  const handleLogout = () => {
    localStorage.removeItem("token");
    setUser(null);
    setGameResults(null);
    setGameActive(false);
  };

  return (
    <div className="App">
      <div id="subRoot">
        <Routes>
          <Route 
            path="/" 
            element={
              !user ? (
                <Auth onLogin={handleAuth} />
              ) : gameActive ? (
                <Game 
                  player={user} 
                  onGameEnd={handleGameEnd}
                />
              ) : gameResults ? (
                <GameResults 
                  results={gameResults}
                  user={user}
                  onBackToGame={handleBackToGame}
                  onLogout={handleLogout}
                />
              ) : (
                <Main 
                  user={user} 
                  onStartGame={handleStartGame}
                  onLogout={handleLogout}
                />
              )
            }
          />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </div>
    </div>
  );
}
