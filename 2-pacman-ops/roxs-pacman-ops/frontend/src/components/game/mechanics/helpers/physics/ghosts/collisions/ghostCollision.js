import axios from "axios";
import Graphics from "../../../graphics/graphics";
import GameResults from "../../../../../../GameResults/GameResults";
import Animator from "../../../graphics/animator/animator";
import playGame from "../../../../playGame";

export default class GhostCollision {
  static collisionConditional(ghost, pacman) {
    return (
      ghost.position.y - ghost.radius <= pacman.position.y + pacman.radius &&
      ghost.position.y + ghost.radius >= pacman.position.y - pacman.radius &&
      ghost.position.x + ghost.radius >= pacman.position.x - pacman.radius &&
      ghost.position.x - ghost.radius <= pacman.position.x + pacman.radius
    );
  }

  static dealWithCollision(ghost, assets, variables, ctx) {
    if (!ghost.isScared && !ghost.isRetreating) {
      assets.characters.pacman.radians = Math.PI / 4;
      cancelAnimationFrame(variables.animationId);
      assets.audioPlayer.stopGhostAudio();
      assets.audioPlayer.playPacmanDeath();
      assets.characters.pacman.isShrinking = true;
      Graphics.runDeathAnimation(variables, ctx, assets);
    } else if (ghost.isScared) {
      variables.score += 200 * Math.pow(2, variables.killCount);
      variables.killCount++;
      ghost.changeRetreatingState();
      ghost.retreatingTimer.start();
      ghost.changeScaredState();
      ghost.assignSprite();
      ghost.checkSpeedMatchesState();
    }
  }

  static checkPacmanLives(
    assets,
    variables,
    ctx,
    endGame = GhostCollision.endGame,
    resetAfterDeath = GhostCollision.resetAfterDeath
  ) {
    if (assets.characters.pacman.lives <= 0) {
      endGame(variables, assets, ctx);
    } else {
      assets.characters.pacman.lives--;
      resetAfterDeath(assets, variables);
    }
  }

  static async endGame(
    variables,
    assets,
    ctx,
    saveScore = GhostCollision.saveScore,
    resetAfterGameOver = GhostCollision.resetAfterGameOver
  ) {
    console.log('🎮 endGame called', { 
      hasOnGameEnd: !!variables.onGameEnd, 
      hasReactRoot: !!variables.reactRoot,
      score: variables.score 
    });
    
    cancelAnimationFrame(variables.animationId);
    Animator.displayPleaseWait(ctx);
    
    let saveResult = null;
    if (variables.player) {
      saveResult = await saveScore(variables);
    }
    
    // Calcular duración del juego en segundos
    const gameEndTime = Date.now();
    const gameDuration = variables.gameStartTime ? 
      Math.floor((gameEndTime - variables.gameStartTime) / 1000) : 0;
    
    console.log('⏱️ Game timing:', {
      startTime: variables.gameStartTime,
      endTime: gameEndTime,
      duration: gameDuration,
      startTimeFormatted: variables.gameStartTime ? new Date(variables.gameStartTime).toISOString() : 'not set',
      endTimeFormatted: new Date(gameEndTime).toISOString()
    });
    
    // Crear objeto con los resultados del juego
    const gameResults = {
      score: variables.score,
      level: variables.level,
      killCount: variables.killCount,
      duration: gameDuration, // Nuevo: duración en segundos
      isVictory: variables.level > 1, // Victoria si completó al menos un nivel
      saveResult,
      player: variables.player
    };
    
    console.log('🎯 Game results:', gameResults);
    
    // Usar la función onGameEnd si está disponible
    if (variables.onGameEnd) {
      console.log('✅ Calling onGameEnd');
      variables.onGameEnd(gameResults);
    } else {
      console.log('❌ No onGameEnd, using fallback with reactRoot');
      // Fallback al comportamiento anterior
      if (variables.reactRoot) {
        variables.reactRoot.render(<GameResults results={gameResults} />);
      }
    }
    
    // Reset después de mostrar resultados
    resetAfterGameOver(assets, variables);
  }

  static async saveScore(
    variables,
    getBackendUrl = GhostCollision.getBackendUrl
  ) {
    const data = {
      username: variables.player.username,
      score: variables.score, // Cambiar de 'points' a 'score' para coincidir con el backend
    };
    try {
      const res = await axios.post(
        getBackendUrl(process.env.REACT_APP_BACKEND_URL),
        data,
        {
          headers: {
            Authorization: localStorage.getItem("token"),
          },
        }
      );
      return `Success: ${res.data.message}`;
    } catch (err) {
      return `Error: ${err.response.data.message}`;
    }
  }

  static getBackendUrl(reactAppUrl) {
    let url;
    if (reactAppUrl) {
      url = `${reactAppUrl}/scores`;
    } else {
      url = "http://localhost:8080/scores";
    }
    return url;
  }

  static resetAfterGameOver(assets, variables) {
    assets.props.pellets.forEach((pellet) => {
      if (pellet.hasBeenEaten) pellet.changeEatenState();
    });
    assets.props.powerUps.forEach((powerUp) => {
      if (powerUp.hasBeenEaten) powerUp.changeEatenState();
    });
    assets.timers.cycleTimer.reset();
    assets.timers.scaredTimer.reset();
    assets.timers.scaredTimer.duration = 7000;
    Object.values(assets.characters.ghosts).forEach((ghost) => {
      ghost.reset();
    });
    assets.characters.pacman.reset();
    assets.characters.pacman.lives = 2;
    variables.lastKeyPressed = "";
    variables.level = 1;
    variables.score = 0;
    variables.killCount = 0;
    variables.start = true;
    window.removeEventListener("keydown", variables.directionEventListener);
    window.removeEventListener(
      "visibilitychange",
      variables.visibilityEventListener
    );
    window.removeEventListener("keydown", variables.pauseEventListener);
  }

  static resetAfterDeath(assets, variables, callbackOne = playGame) {
    assets.characters.pacman.reset();
    variables.lastKeyPressed = "";
    assets.timers.cycleTimer.reset();
    assets.timers.scaredTimer.reset();
    Object.values(assets.characters.ghosts).forEach((ghost) => {
      ghost.reset();
    });
    assets.timers.cycleTimer.start();
    assets.audioPlayer.ghostAudioWantsToPlay = true;
    callbackOne(variables.player, variables.reactRoot);
  }
}
