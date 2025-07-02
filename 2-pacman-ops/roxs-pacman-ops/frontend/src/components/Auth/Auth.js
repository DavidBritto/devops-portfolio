import React, { useState, useEffect } from "react";
import axios from "axios";
import { Profanity, ProfanityOptions } from "@2toad/profanity";
import "./Auth.css";
import Footer from "../footer/footer";

const usersUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/users`
  : "http://localhost:8080/users";

const authUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/auth`
  : "http://localhost:8080/auth";

const Auth = ({ onLogin }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    username: "",
    password: "",
    email: "",
    fullName: "",
    team: "",
    isParticipant: false
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [containerInfo, setContainerInfo] = useState({
    platform: "Unknown",
    hostname: "Unknown", 
    environment: "Unknown"
  });

  const options = new ProfanityOptions();
  options.wholeWord = false;
  const profanity = new Profanity(options);

  useEffect(() => {
    getContainerInfo();
  }, []);

  const getContainerInfo = async () => {
    try {
      const containerUrl = process.env.REACT_APP_BACKEND_URL
        ? `${process.env.REACT_APP_BACKEND_URL}/container-info`
        : "http://localhost:8080/container-info";
      const response = await axios.get(containerUrl);
      setContainerInfo(response.data);
    } catch (error) {
      console.log("No se pudo obtener información del contenedor", error);
      setContainerInfo({
        platform: process.env.KUBERNETES_SERVICE_HOST ? "Kubernetes" : "Docker",
        hostname: window.location.hostname,
        environment: process.env.NODE_ENV || "development"
      });
    }
  };

  const handleInputChange = (field) => ({ target }) => {
    setFormData(prev => ({
      ...prev,
      [field]: target.value
    }));
    setError(""); // Clear error when user types
  };

  const handleCheckboxChange = ({ target }) => {
    setFormData(prev => ({
      ...prev,
      isParticipant: target.checked
    }));
  };

  const handleEnter = (event) => {
    if (event.key === "Enter") {
      handleSubmit();
    }
  };

  const validateEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  const validateForm = () => {
    const { username, password, email, fullName, isParticipant } = formData;

    if (!username || !password) {
      setError("Username and password are required");
      return false;
    }

    if (username.includes(" ")) {
      setError("Username cannot contain spaces");
      return false;
    }

    if (username.length < 3 || username.length > 15) {
      setError("Username must be 3-15 characters long");
      return false;
    }

    if (profanity.exists(username)) {
      setError("Username contains inappropriate content");
      return false;
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters long");
      return false;
    }

    if (!isLogin) {
      if (isParticipant && !email) {
        setError("Email is required for challenge participants");
        return false;
      }

      if (isParticipant && !fullName) {
        setError("Full name is required for challenge participants");
        return false;
      }

      if (email && !validateEmail(email)) {
        setError("Please enter a valid email address");
        return false;
      }
    }

    return true;
  };

  const handleSubmit = async () => {
    if (!validateForm()) return;

    setLoading(true);
    setError("");

    try {
      if (isLogin) {
        // Login
        const response = await axios.post(authUrl, {
          username: formData.username,
          password: formData.password,
        });

        if (response.status === 200) {
          const { token, user } = response.data;
          const userData = {
            ...user,
            token: token
          };
          localStorage.setItem("token", token);
          localStorage.setItem("user", JSON.stringify(userData));
          onLogin(userData);
        }
      } else {
        // Signup
        const userData = {
          username: formData.username,
          password: formData.password,
          email: formData.isParticipant ? formData.email : "",
          fullName: formData.isParticipant ? formData.fullName : "",
          team: formData.isParticipant ? formData.team : "",
          isParticipant: formData.isParticipant,
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

        const signupResponse = await axios.post(usersUrl, userData);
        
        if (signupResponse.status === 201) {
          // Auto-login after signup
          const loginResponse = await axios.post(authUrl, {
            username: formData.username,
            password: formData.password,
          });

          if (loginResponse.status === 200) {
            const { token, user } = loginResponse.data;
            const userData = {
              ...user,
              token: token,
              isParticipant: formData.isParticipant
            };
            localStorage.setItem("token", token);
            localStorage.setItem("user", JSON.stringify(userData));
            onLogin(userData);
          }
        }
      }
    } catch (err) {
      setError(err.response?.data?.message || "An error occurred. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const toggleMode = () => {
    setIsLogin(!isLogin);
    setError("");
    setFormData({
      username: "",
      password: "",
      email: "",
      fullName: "",
      team: "",
      isParticipant: false
    });
  };

  return (
    <div className="auth-container">
      <div className="auth-background">
        <div className="auth-card">
          <div className="auth-header">
            <h1>{isLogin ? "🎮 Login" : "🚀 Join Challenge"}</h1>
            <p className="auth-subtitle">
              {isLogin ? "Welcome back, gamer!" : "90 Days DevOps Challenge"}
            </p>
          </div>

          {/* Container Info */}
          <div className="container-info-compact">
            <span className="info-item">
              <span className="info-icon">🏗️</span>
              {containerInfo.platform}
            </span>
            <span className="info-item">
              <span className="info-icon">🌐</span>
              {containerInfo.hostname}
            </span>
            <span className="info-item">
              <span className="info-icon">⚙️</span>
              {containerInfo.environment}
            </span>
          </div>

          <form className="auth-form" onSubmit={(e) => e.preventDefault()}>
            <div className="form-group">
              <input
                type="text"
                placeholder="Username"
                value={formData.username}
                onChange={handleInputChange("username")}
                onKeyDown={handleEnter}
                className="auth-input"
                autoComplete="username"
              />
            </div>

            <div className="form-group">
              <input
                type="password"
                placeholder="Password"
                value={formData.password}
                onChange={handleInputChange("password")}
                onKeyDown={handleEnter}
                className="auth-input"
                autoComplete={isLogin ? "current-password" : "new-password"}
              />
            </div>

            {!isLogin && (
              <>
                <div className="participant-toggle">
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={formData.isParticipant}
                      onChange={handleCheckboxChange}
                    />
                    <span className="checkmark"></span>
                    <span className="checkbox-text">
                      I'm participating in the 90 Days DevOps Challenge
                    </span>
                  </label>
                </div>

                {formData.isParticipant && (
                  <div className="participant-fields">
                    <div className="form-group">
                      <input
                        type="email"
                        placeholder="Email"
                        value={formData.email}
                        onChange={handleInputChange("email")}
                        onKeyDown={handleEnter}
                        className="auth-input"
                        autoComplete="email"
                      />
                    </div>

                    <div className="form-group">
                      <input
                        type="text"
                        placeholder="Full Name"
                        value={formData.fullName}
                        onChange={handleInputChange("fullName")}
                        onKeyDown={handleEnter}
                        className="auth-input"
                        autoComplete="name"
                      />
                    </div>

                    <div className="form-group">
                      <input
                        type="text"
                        placeholder="Team (optional)"
                        value={formData.team}
                        onChange={handleInputChange("team")}
                        onKeyDown={handleEnter}
                        className="auth-input"
                      />
                    </div>
                  </div>
                )}
              </>
            )}

            {error && (
              <div className="error-message">
                <span className="error-icon">⚠️</span>
                {error}
              </div>
            )}

            <button
              type="button"
              onClick={handleSubmit}
              disabled={loading}
              className={`auth-button ${loading ? 'loading' : ''}`}
            >
              {loading ? (
                <>
                  <span className="spinner"></span>
                  {isLogin ? "Logging in..." : "Creating account..."}
                </>
              ) : (
                <>
                  {isLogin ? "🎮 Play Game" : "🚀 Join Challenge"}
                </>
              )}
            </button>

            <div className="auth-toggle">
              <p>
                {isLogin ? "New to the challenge? " : "Already have an account? "}
                <button
                  type="button"
                  onClick={toggleMode}
                  className="toggle-button"
                  disabled={loading}
                >
                  {isLogin ? "Sign up here" : "Login here"}
                </button>
              </p>
            </div>
          </form>

          {!isLogin && formData.isParticipant && (
            <div className="challenge-info">
              <h4>🎯 Challenge Features:</h4>
              <div className="features-grid">
                <div className="feature-item">
                  <span className="feature-icon">🏆</span>
                  <span>Track victories</span>
                </div>
                <div className="feature-item">
                  <span className="feature-icon">👥</span>
                  <span>Compete globally</span>
                </div>
                <div className="feature-item">
                  <span className="feature-icon">📊</span>
                  <span>View statistics</span>
                </div>
                <div className="feature-item">
                  <span className="feature-icon">🚀</span>
                  <span>Learn DevOps</span>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
      <Footer />
    </div>
  );
};

export default Auth;
