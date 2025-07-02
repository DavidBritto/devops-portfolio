import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import Footer from '../footer/footer';
import './GameResults.css';

const GameResults = ({ results, user, onBackToGame, onLogout }) => {
  const [leaderboard, setLeaderboard] = useState([]);
  const [userStats, setUserStats] = useState(null);
  const [containerInfo, setContainerInfo] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('results');

  // Mapear results a gameData para compatibilidad
  const gameData = {
    finalScore: results?.score || 0,
    level: results?.level || 1,
    gameDuration: results?.duration || 0,
    isVictory: results?.isVictory || false,
    killCount: results?.killCount || 0
  };

  const fetchResultsData = useCallback(async () => {
    try {
      setLoading(true);
      
      const backendUrl = process.env.REACT_APP_BACKEND_URL || 'http://localhost:8080';
      
      // Fetch leaderboard
      const scoresResponse = await axios.get(`${backendUrl}/scores`);
      console.log('📊 Scores response:', scoresResponse.data);
      
      // Fetch user stats if available
      if (user?.username) {
        try {
          const statsResponse = await axios.get(`${backendUrl}/user-stats/${user.username}`);
          setUserStats(statsResponse.data);
        } catch (error) {
          console.log('Could not fetch user stats:', error.message);
        }
      }
      
      // Fetch container info
      try {
        const containerResponse = await axios.get(`${backendUrl}/container-info`);
        setContainerInfo(containerResponse.data);
      } catch (error) {
        console.log('Could not fetch container info:', error.message);
      }
      
      setLeaderboard(scoresResponse.data.scores || []);
      
    } catch (error) {
      console.error('Error fetching results data:', error);
      // Set mock data on error
      setLeaderboard([
        { username: 'roxsross', points: 5500 },
        { username: 'devops_hero', points: 4200 },
        { username: 'k8s_master', points: 3800 },
        { username: 'docker_ninja', points: 3400 },
        { username: 'cloud_warrior', points: 2900 }
      ]);
    } finally {
      setLoading(false);
    }
  }, [user?.username]);

  useEffect(() => {
    fetchResultsData();
  }, [fetchResultsData]);

  const getScoreRank = () => {
    if (!gameData?.finalScore || leaderboard.length === 0) return null;
    
    const rank = leaderboard.findIndex(score => 
      gameData.finalScore >= (score.points || score.score)
    );
    
    return rank === -1 ? leaderboard.length + 1 : rank + 1;
  };

  const getScoreMessage = () => {
    const score = gameData?.finalScore || 0;
    const rank = getScoreRank();
    
    if (score === 0) return "Better luck next time! 🎮";
    if (rank === 1) return "🏆 NEW HIGH SCORE! You're the champion!";
    if (rank <= 3) return `🥉 Amazing! You're in the top 3!`;
    if (rank <= 10) return `🎯 Great job! You're in the top 10!`;
    return `🎮 Good game! Keep practicing!`;
  };

  const formatTime = (seconds) => {
    // Si no hay tiempo registrado, mostrar un mensaje más claro
    if (!seconds || seconds === 0) {
      return "-- : --";
    }
    
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  if (loading) {
    return (
      <div className="game-results">
        <div className="results-card">
          <div className="loading-container">
            <div className="spinner-large"></div>
            <p>Loading results...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="game-results">
      <div className="results-container">
        
        {/* Main Results Card */}
        <div className="results-card main-results">
          <div className="results-header">
            <h1>🎮 Game Complete!</h1>
            <p className="score-message">{getScoreMessage()}</p>
          </div>

          <div className="score-display">
            <div className="final-score">
              <span className="score-label">Final Score</span>
              <span className="score-value">{gameData?.finalScore?.toLocaleString() || 0}</span>
            </div>
            
            {getScoreRank() && (
              <div className="rank-display">
                <span className="rank-label">Your Rank</span>
                <span className="rank-value">#{getScoreRank()}</span>
              </div>
            )}
          </div>

          <div className="game-stats-grid">
            <div className="stat-item">
              <span className="stat-icon">⏱️</span>
              <span className="stat-label">Time</span>
              <span className="stat-value">
                {formatTime(gameData?.gameDuration || 0)}
              </span>
            </div>
            
            <div className="stat-item">
              <span className="stat-icon">🎯</span>
              <span className="stat-label">Level</span>
              <span className="stat-value">{gameData?.level || 1}</span>
            </div>
            
            <div className="stat-item">
              <span className="stat-icon">🏆</span>
              <span className="stat-label">Victory</span>
              <span className="stat-value">
                {gameData?.isVictory ? "Mission Complete! 🚀" : "Keep Learning! 💪"}
              </span>
            </div>

            {containerInfo && (
              <div className="stat-item">
                <span className="stat-icon">🏗️</span>
                <span className="stat-label">Platform</span>
                <span className="stat-value">{containerInfo.platform}</span>
              </div>
            )}
          </div>

          {user?.isParticipant && (
            <div className="challenge-badge">
              <span className="badge-icon">🚀</span>
              <span className="badge-text">90 Days DevOps Challenge Participant</span>
            </div>
          )}
        </div>

        {/* Navigation Tabs */}
        <div className="results-tabs">
          <button 
            className={`tab-button ${activeTab === 'results' ? 'active' : ''}`}
            onClick={() => setActiveTab('results')}
          >
            🎯 Your Results
          </button>
          <button 
            className={`tab-button ${activeTab === 'leaderboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('leaderboard')}
          >
            🏆 Leaderboard
          </button>
          {userStats && (
            <button 
              className={`tab-button ${activeTab === 'profile' ? 'active' : ''}`}
              onClick={() => setActiveTab('profile')}
            >
              👤 My Profile
            </button>
          )}
        </div>

        {/* Tab Content */}
        <div className="tab-content">
          
          {activeTab === 'results' && (
            <div className="results-card">
              <h3>📊 Game Statistics</h3>
              <div className="detailed-stats">
                <div className="stats-row">
                  <span>Game Date:</span>
                  <span>{new Date().toLocaleDateString()}</span>
                </div>
                <div className="stats-row">
                  <span>Game Time:</span>
                  <span>{new Date().toLocaleTimeString()}</span>
                </div>
                <div className="stats-row">
                  <span>Player:</span>
                  <span>{user?.username || 'Anonymous'}</span>
                </div>
                {gameData?.pellets && (
                  <div className="stats-row">
                    <span>Pellets Collected:</span>
                    <span>{gameData.pellets}</span>
                  </div>
                )}
                {gameData?.powerUps && (
                  <div className="stats-row">
                    <span>Power-ups Used:</span>
                    <span>{gameData.powerUps}</span>
                  </div>
                )}
                {gameData?.ghosts && (
                  <div className="stats-row">
                    <span>Ghosts Defeated:</span>
                    <span>{gameData.ghosts}</span>
                  </div>
                )}
              </div>
            </div>
          )}

          {activeTab === 'leaderboard' && (
            <div className="results-card">
              <h3>🏆 Top Players</h3>
              <div className="leaderboard-list">
                {leaderboard.slice(0, 10).map((score, index) => (
                  <div 
                    key={index} 
                    className={`leaderboard-item ${
                      score.username === user?.username ? 'current-user' : ''
                    } ${index < 3 ? 'top-three' : ''}`}
                  >
                    <div className="rank-position">
                      {index === 0 && <span className="trophy">🥇</span>}
                      {index === 1 && <span className="trophy">🥈</span>}
                      {index === 2 && <span className="trophy">🥉</span>}
                      {index > 2 && <span className="rank-number">#{index + 1}</span>}
                    </div>
                    <div className="player-info">
                      <span className="player-name">{score.username}</span>
                      {score.username === user?.username && (
                        <span className="you-badge">YOU</span>
                      )}
                    </div>
                    <div className="player-score">
                      {(score.points || score.score)?.toLocaleString()}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {activeTab === 'profile' && userStats && (
            <div className="results-card">
              <h3>👤 Your Profile</h3>
              <div className="profile-stats">
                <div className="profile-header">
                  <div className="avatar">
                    {user.username?.charAt(0).toUpperCase()}
                  </div>
                  <div className="profile-info">
                    <h4>{user.username}</h4>
                    {user.isParticipant && (
                      <span className="participant-badge">
                        🚀 Challenge Participant
                      </span>
                    )}
                  </div>
                </div>
                
                <div className="profile-stats-grid">
                  <div className="profile-stat">
                    <span className="stat-icon">🎮</span>
                    <span className="stat-value">{userStats.gamesPlayed || 0}</span>
                    <span className="stat-label">Games Played</span>
                  </div>
                  <div className="profile-stat">
                    <span className="stat-icon">🏆</span>
                    <span className="stat-value">{userStats.highScore || 0}</span>
                    <span className="stat-label">High Score</span>
                  </div>
                  <div className="profile-stat">
                    <span className="stat-icon">🎯</span>
                    <span className="stat-value">{userStats.victories || 0}</span>
                    <span className="stat-label">Victories</span>
                  </div>
                  <div className="profile-stat">
                    <span className="stat-icon">📊</span>
                    <span className="stat-value">{userStats.totalScore || 0}</span>
                    <span className="stat-label">Total Score</span>
                  </div>
                </div>

                {userStats.achievements && userStats.achievements.length > 0 && (
                  <div className="achievements">
                    <h4>🏅 Achievements</h4>
                    <div className="achievement-list">
                      {userStats.achievements.map((achievement, index) => (
                        <span key={index} className="achievement-badge">
                          {achievement}
                        </span>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="action-buttons">
          <button className="action-btn primary" onClick={onBackToGame}>
            🎮 Play Again
          </button>
          <button className="action-btn secondary" onClick={onLogout}>
            � Logout
          </button>
        </div>
      </div>
      <Footer />
    </div>
  );
};

export default GameResults;
