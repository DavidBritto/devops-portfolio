import React from "react";
import "./footer.css";

export default function Footer() {
  return (
    <footer>
      <div className="footer-content">
        <div className="footer-main">
          <span className="footer-text" data-testid="footer-text">
            by{" "}
            <a href="https://roxs.295devops.com" target="_blank" rel="noopener noreferrer">
              <strong>RoxsRoss</strong>
            </a>
          </span>
          <span className="footer-separator">•</span>
          <span className="footer-subtext">
            juego basado en Pac-Man clásico by @Namco
          </span>
          <span className="footer-separator">•</span>
          <span className="footer-credits">
            90 Days DevOps Challenge by Roxs
          </span>
        </div>
      </div>
    </footer>
  );
}
