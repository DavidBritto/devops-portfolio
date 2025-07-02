import React, { useEffect } from "react";
import "./game.css";
import playGame from "./mechanics/playGame";
import Footer from "../footer/footer";

export default function Game({ player, onGameEnd, callback = playGame }) {
  useEffect(() => {
    callback(player, null, onGameEnd);
  }, [callback, player, onGameEnd]);

  const handleDirection = (direction) => {
    const arrow = new KeyboardEvent("keydown", { key: direction });
    window.dispatchEvent(arrow);
  };

  return (
    <div className="game">
      <div className="game-content">
        <h1>¡Vamos a jugar{player ? " " + player.username : null}!</h1>
        <div className="game-area">
          <canvas
            id="info"
            className="info"
            data-testid="info"
            width="600"
            height="30"
          ></canvas>
          <canvas
            id="board"
            className="board"
            data-testid="board"
            width="896"
            height="992"
          ></canvas>
        </div>
        <div className="dpad">
          <img
            src="./images/dpad.png"
            alt="dpad"
            useMap="#dpad"
            height="200px"
            width="200px"
            data-testid="dpad"
          ></img>
          <map name="dpad" data-testid="dpad-map">
          <area
            className="up"
            data-testid="up"
            shape="rect"
            coords="66,0,133,66"
            alt="up"
            onClick={() => handleDirection("ArrowUp")}
          ></area>
          <area
            className="left"
            data-testid="left"
            shape="rect"
            coords="0,66,66,133"
            alt="left"
            onClick={() => handleDirection("ArrowLeft")}
          ></area>
          <area
            className="right"
            data-testid="right"
            shape="rect"
            coords="133,66,200,133"
            alt="right"
            onClick={() => handleDirection("ArrowRight")}
          ></area>
          <area
            className="down"
            data-testid="down"
            shape="rect"
            coords="66,133,133,200"
            alt="down"
            onClick={() => handleDirection("ArrowDown")}
          ></area>
        </map>
        </div>
      </div>
      <Footer />
    </div>
  );
}
