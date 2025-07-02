import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './DevOpsStats.css';

const DevOpsStats = ({ isVisible, currentUser }) => {
  const [stats, setStats] = useState({
    containerInfo: { platform: 'Loading...', hostname: 'Loading...' },
    liveStats: { onlinePlayers: 0, gamesInProgress: 0 },
    userRank: { position: 0, total: 0 }
  });
  const [isMinimized, setIsMinimized] = useState(false);

  useEffect(() => {
    if (isVisible) {
      fetchStats();
      const interval = setInterval(fetchStats, 30000); // Update every 30 seconds
      return () => clearInterval(interval);
    }
  }, [isVisible]);

  const fetchStats = async () => {
    try {
      // Fetch container info
      const containerResponse = await axios.get(
        `${process.env.REACT_APP_BACKEND_URL}/container-info`
      );
      
      // Fetch live stats
      const liveResponse = await axios.get(
        `${process.env.REACT_APP_BACKEND_URL}/live-stats`
      );
      
      // Fetch user rank if logged in
      let userRank = { position: 0, total: 0 };
      if (currentUser) {
        const rankResponse = await axios.get(
          `${process.env.REACT_APP_BACKEND_URL}/user-rank/${currentUser}`
        );
        userRank = rankResponse.data;
      }

      setStats({
        containerInfo: containerResponse.data,
        liveStats: liveResponse.data,
        userRank
      });
    } catch (error) {
      console.error('Error fetching DevOps stats:', error);
      // Set default values on error
      setStats({
        containerInfo: { 
          platform: 'Unknown', 
          hostname: window.location.hostname,
          environment: 'production'
        },
        liveStats: { onlinePlayers: 0, gamesInProgress: 0 },
        userRank: { position: 0, total: 0 }
      });
    }
  };

  if (!isVisible) return null;

  return (
    <div className={`devops-stats ${isMinimized ? 'minimized' : ''}`}>
      <div className="stats-header">
        <h3>🚀 DevOps Challenge Stats</h3>
        <button 
          className="minimize-btn"
          onClick={() => setIsMinimized(!isMinimized)}
        >
          {isMinimized ? '📊' : '📉'}
        </button>
      </div>

      {!isMinimized && (
        <div className="stats-content">
          {/* Infrastructure Info */}
          <div className="stat-section">
            <h4>🏗️ Infrastructure</h4>
            <div className="stat-item">
              <span className="stat-label">Platform:</span>
              <span className={`stat-value platform-${stats.containerInfo.platform?.toLowerCase()}`}>
                {stats.containerInfo.platform}
              </span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Host:</span>
              <span className="stat-value">{stats.containerInfo.hostname}</span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Environment:</span>
              <span className={`stat-value env-${stats.containerInfo.environment}`}>
                {stats.containerInfo.environment}
              </span>
            </div>
          </div>

          {/* Live Stats */}
          <div className="stat-section">
            <h4>📊 Live Stats</h4>
            <div className="stat-item">
              <span className="stat-label">Online Players:</span>
              <span className="stat-value live-count">
                {stats.liveStats.onlinePlayers}
              </span>
            </div>
            <div className="stat-item">
              <span className="stat-label">Games in Progress:</span>
              <span className="stat-value live-count">
                {stats.liveStats.gamesInProgress}
              </span>
            </div>
          </div>

          {/* User Rank (if logged in) */}
          {currentUser && (
            <div className="stat-section">
              <h4>🏆 Your Rank</h4>
              <div className="stat-item">
                <span className="stat-label">Position:</span>
                <span className="stat-value rank-position">
                  #{stats.userRank.position} of {stats.userRank.total}
                </span>
              </div>
            </div>
          )}

          {/* Challenge Progress */}
          <div className="stat-section challenge-progress">
            <h4>🎯 90 Days Challenge</h4>
            <div className="progress-info">
              <span>Day {Math.floor((new Date() - new Date('2024-01-01')) / (1000 * 60 * 60 * 24)) % 90 + 1} of 90</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DevOpsStats;
