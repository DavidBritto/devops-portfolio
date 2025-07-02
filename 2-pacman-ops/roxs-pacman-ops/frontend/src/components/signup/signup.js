import React, { useState, useEffect } from "react";
import axios from "axios";
import "./signup.css";
import { Profanity, ProfanityOptions } from "@2toad/profanity";

const usersUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/users`
  : "http://localhost:8080/users";

const authUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/auth`
  : "http://localhost:8080/auth";

const redirectUrl = process.env.REACT_APP_URL
  ? process.env.REACT_APP_URL
  : "http://localhost:8000";

export default function Signup() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [email, setEmail] = useState("");
  const [fullName, setFullName] = useState("");
  const [team, setTeam] = useState("");
  const [error, setError] = useState("");
  const [containerInfo, setContainerInfo] = useState({
    platform: "Unknown",
    hostname: "Unknown",
    environment: "Unknown"
  });
  const [isParticipant, setIsParticipant] = useState(false);

  const options = new ProfanityOptions();
  options.wholeWord = false;
  const profanity = new Profanity(options);

  // Detectar información del contenedor al cargar el componente
  useEffect(() => {
    getContainerInfo();
  }, []);

  const getContainerInfo = async () => {
    try {
      const response = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/container-info`);
      setContainerInfo(response.data);
    } catch (error) {
      console.log("No se pudo obtener información del contenedor", error);
      // Información por defecto basada en variables de entorno
      setContainerInfo({
        platform: process.env.KUBERNETES_SERVICE_HOST ? "Kubernetes" : "Docker",
        hostname: window.location.hostname,
        environment: process.env.NODE_ENV || "development"
      });
    }
  };

  const handleUsername = ({ target }) => {
    setUsername(target.value);
  };

  const handlePassword = ({ target }) => {
    setPassword(target.value);
  };

  const handleEmail = ({ target }) => {
    setEmail(target.value);
  };

  const handleFullName = ({ target }) => {
    setFullName(target.value);
  };

  const handleTeam = ({ target }) => {
    setTeam(target.value);
  };

  const handleParticipantToggle = ({ target }) => {
    setIsParticipant(target.checked);
  };

  const handleEnter = (event) => {
    const buttonEl = document.querySelector("#signup-button");
    if (event.key === "Enter") buttonEl.click();
  };

  const handleSubmit = () => {
    let nameError = document.getElementById("error-message");
    
    // Validaciones mejoradas
    if (username.includes(" ")) {
      nameError.innerText = "Username cannot contain any spaces";
    } else if (username.length < 3 || username.length > 15) {
      nameError.innerText = "Username must be 3-15 characters long";
    } else if (profanity.exists(username)) {
      nameError.innerText = "No profanity!";
    } else if (password.length < 8) {
      nameError.innerText = "Password must be at least 8 characters long";
    } else if (isParticipant && !email) {
      nameError.innerText = "Email is required for participants";
    } else if (isParticipant && !fullName) {
      nameError.innerText = "Full name is required for participants";
    } else if (email && !validateEmail(email)) {
      nameError.innerText = "Please enter a valid email address";
    } else {
      // Crear usuario con información extendida
      const userData = {
        username: username,
        password: password,
        email: isParticipant ? email : "",
        fullName: isParticipant ? fullName : "",
        team: isParticipant ? team : "",
        isParticipant: isParticipant,
        containerInfo: containerInfo,
        registrationDate: new Date().toISOString(),
        devOpsChallenge: "90DaysWithRoxs",
        gameStats: {
          gamesPlayed: 0,
          highScore: 0,
          totalScore: 0,
          victories: 0,
          achievements: []
        }
      };

      axios
        .post(usersUrl, userData)
        .then((res) => {
          if (res.status === 201) {
            login();
          } else {
            throw res;
          }
        })
        .catch((err) => setError(err.response?.data?.message || "Error creating user"));
    }
  };

  const validateEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const login = () => {
    axios
      .post(authUrl, {
        username: username,
        password: password,
      })
      .then((res) => {
        if (res.status === 200) {
          localStorage.setItem("token", res.data);
          window.location.href = redirectUrl;
        } else {
          throw res;
        }
      })
      .catch((err) => setError(err.response.data.message));
  };

  return (
    <div className="signup">
      <h1>Sign Up - 90 Days DevOps Challenge</h1>
      
      {/* Información del contenedor */}
      <div className="container-info">
        <h3>🚀 Infrastructure Info</h3>
        <div className="info-grid">
          <span><strong>Platform:</strong> {containerInfo.platform}</span>
          <span><strong>Host:</strong> {containerInfo.hostname}</span>
          <span><strong>Environment:</strong> {containerInfo.environment}</span>
        </div>
      </div>

      <div className="border">
        <input
          placeholder="Username"
          value={username}
          onChange={handleUsername}
          onKeyDown={handleEnter}
        />
        <br />
        
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={handlePassword}
          onKeyDown={handleEnter}
        />
        <br />

        {/* Checkbox para participante */}
        <div className="participant-toggle">
          <label>
            <input
              type="checkbox"
              checked={isParticipant}
              onChange={handleParticipantToggle}
            />
            ¿Eres participante del desafío 90DaysDevOps?
          </label>
        </div>

        {/* Campos adicionales para participantes */}
        {isParticipant && (
          <div className="participant-fields">
            <input
              type="email"
              placeholder="Email"
              value={email}
              onChange={handleEmail}
              onKeyDown={handleEnter}
            />
            <br />
            
            <input
              placeholder="Full Name"
              value={fullName}
              onChange={handleFullName}
              onKeyDown={handleEnter}
            />
            <br />
            
            <input
              placeholder="Team (opcional)"
              value={team}
              onChange={handleTeam}
              onKeyDown={handleEnter}
            />
            <br />
          </div>
        )}

        <button id="signup-button" onClick={handleSubmit}>
          {isParticipant ? "Join Challenge" : "Sign up"}
        </button>
        
        <p className="error-message" id="error-message">
          {error}
        </p>

        {/* Información adicional para participantes */}
        {isParticipant && (
          <div className="challenge-info">
            <h4>🎮 Challenge Features:</h4>
            <ul>
              <li>Track your Pacman victories</li>
              <li>Compete with other DevOps enthusiasts</li>
              <li>Monitor your progress in MongoDB</li>
              <li>View infrastructure metrics</li>
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
