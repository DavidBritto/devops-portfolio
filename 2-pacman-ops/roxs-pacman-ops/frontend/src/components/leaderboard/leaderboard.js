import axios from "axios";
import "./leaderboard.css";
import React from "react";
import Game from "../game/game";
import Main from "../main/main";
import { useEffect, useState } from "react";

const scoresUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/scores`
  : "http://localhost:8080/scores";

const participantsUrl = process.env.REACT_APP_BACKEND_URL
  ? `${process.env.REACT_APP_BACKEND_URL}/participants`
  : "http://localhost:8080/participants";

export default function Leaderboard({ variables }) {
  const [scores, setScores] = useState([]);
  const [participants, setParticipants] = useState([]);
  const [containerStats, setContainerStats] = useState({});
  const [error, setError] = useState(false);
  const [activeTab, setActiveTab] = useState('scores'); // 'scores', 'participants', 'stats'

  const fetchScores = async () => {
    try {
      const res = await axios.get(scoresUrl);
      const scores = res.data.scores;
      while (scores.length < 10) {
        scores.push({
          username: "--",
          points: "--",
        });
      }
      setScores(scores);
    } catch (err) {
      setError(true);
    }
  };

  const fetchParticipants = async () => {
    try {
      const res = await axios.get(participantsUrl);
      setParticipants(res.data.participants || []);
    } catch (err) {
      console.log("Error fetching participants:", err);
    }
  };

  const fetchContainerStats = async () => {
    try {
      const res = await axios.get(`${process.env.REACT_APP_BACKEND_URL}/container-stats`);
      setContainerStats(res.data);
    } catch (err) {
      console.log("Error fetching container stats:", err);
      setContainerStats({
        totalGames: 0,
        totalParticipants: 0,
        avgScore: 0,
        topScore: 0
      });
    }
  };

  useEffect(() => {
    fetchScores();
    fetchParticipants();
    fetchContainerStats();
  }, []);

  const resetVariables = () => {
    variables.score = 0;
    variables.start = true;
  };

  const handlePlayAgain = () => {
    resetVariables();
    variables.reactRoot.render(
      <Game player={variables.player} reactRoot={variables.reactRoot} />
    );
  };

  const handleChangePlayer = () => {
    resetVariables();
    variables.reactRoot.render(
      <Main user={variables.player} reactRoot={variables.reactRoot} />
    );
  };

  return (
    <div className="leaderboard">
      <h1>🎮 90 Days DevOps Challenge - Game Over</h1>
      <h4>You scored {variables.score} points</h4>
      
      {/* Navigation Tabs */}
      <div className="tab-navigation">
        <button 
          className={activeTab === 'scores' ? 'active' : ''}
          onClick={() => setActiveTab('scores')}
        >
          🏆 High Scores
        </button>
        <button 
          className={activeTab === 'participants' ? 'active' : ''}
          onClick={() => setActiveTab('participants')}
        >
          👥 Participants
        </button>
        <button 
          className={activeTab === 'stats' ? 'active' : ''}
          onClick={() => setActiveTab('stats')}
        >
          📊 Challenge Stats
        </button>
      </div>

      {/* Scores Tab */}
      {activeTab === 'scores' && (
        <div className="tab-content">
          {error ? (
            <p className="error" data-testid="error">
              Oops, something went wrong!
            </p>
          ) : (
            <table className="list">
              {scores.length !== 10 ? (
                <tbody>
                  <tr>
                    <td className="wait-message" data-testid="wait-message">
                      Please wait a moment...
                    </td>
                  </tr>
                </tbody>
              ) : (
                <tbody>
                  <tr>
                    <th className="rank-header">Rank</th>
                    <th className="name-header">Name</th>
                    <th className="score-header">Score</th>
                  </tr>
                  {scores.map((score, index) => {
                    return (
                      <tr className="entry" key={index} aria-label={index}>
                        <td className="rank">{index + 1}</td>
                        <td className="name">{score.username}</td>
                        <td className="points">{score.points}</td>
                      </tr>
                    );
                  })}
                </tbody>
              )}
            </table>
          )}
        </div>
      )}

      {/* Participants Tab */}
      {activeTab === 'participants' && (
        <div className="tab-content">
          <div className="participants-grid">
            {participants.length > 0 ? (
              participants.map((participant, index) => (
                <div key={index} className="participant-card">
                  <h3>{participant.fullName || participant.username}</h3>
                  <div className="participant-info">
                    <span>🎯 Username: {participant.username}</span>
                    <span>🏢 Team: {participant.team || 'Individual'}</span>
                    <span>🎮 Games: {participant.gameStats?.gamesPlayed || 0}</span>
                    <span>🏆 Best Score: {participant.gameStats?.highScore || 0}</span>
                    <span>🥇 Victories: {participant.gameStats?.victories || 0}</span>
                    <span>📅 Joined: {new Date(participant.registrationDate).toLocaleDateString()}</span>
                  </div>
                  <div className="container-badge">
                    <span>{participant.containerInfo?.platform || 'Unknown'}</span>
                  </div>
                </div>
              ))
            ) : (
              <p>No participants found</p>
            )}
          </div>
        </div>
      )}

      {/* Stats Tab */}
      {activeTab === 'stats' && (
        <div className="tab-content">
          <div className="stats-grid">
            <div className="stat-card">
              <h3>🎮 Total Games</h3>
              <span className="stat-number">{containerStats.totalGames || 0}</span>
            </div>
            <div className="stat-card">
              <h3>👥 Participants</h3>
              <span className="stat-number">{containerStats.totalParticipants || participants.length}</span>
            </div>
            <div className="stat-card">
              <h3>📊 Average Score</h3>
              <span className="stat-number">{containerStats.avgScore || 0}</span>
            </div>
            <div className="stat-card">
              <h3>🏆 Top Score</h3>
              <span className="stat-number">{containerStats.topScore || 0}</span>
            </div>
          </div>
          
          <div className="infrastructure-info">
            <h3>🚀 Infrastructure Overview</h3>
            <div className="infra-details">
              <span>Platform Distribution:</span>
              <div className="platform-stats">
                {participants.reduce((acc, p) => {
                  const platform = p.containerInfo?.platform || 'Unknown';
                  acc[platform] = (acc[platform] || 0) + 1;
                  return acc;
                }, {})}
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="buttons">
        <button className="play-again" onClick={handlePlayAgain}>
          🎮 Play Again
        </button>
        <button className="home" onClick={handleChangePlayer}>
          🏠 Home
        </button>
      </div>
    </div>
  );
}
