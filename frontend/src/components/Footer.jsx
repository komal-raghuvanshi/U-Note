function Footer({ onNavigate }) {
  const handleNav = (e, path) => {
    e.preventDefault()
    if (onNavigate) onNavigate(path)
  }

  return (
    <footer className="footer">
      <div className="footer-container">
        <div className="footer-grid">
          {/* Left: Brand */}
          <div className="footer-brand">
            <div className="footer-logo-wrapper">
              <img src="/favicon.png" alt="U-NOTE Logo" className="footer-logo-icon" />
              <span className="footer-logo">U-NOTE</span>
            </div>
            <p className="footer-tagline">RGPV Notes &amp; Study Resources Platform</p>
          </div>

          {/* Center: Nav Links */}
          <nav className="footer-nav">
            <ul className="footer-nav-links">
              <li>
                <a href="/" className="footer-nav-link" onClick={(e) => handleNav(e, '/')}>
                  Home
                </a>
              </li>
              <li>
                <a href="/resources" className="footer-nav-link" onClick={(e) => handleNav(e, '/resources')}>
                  Resources
                </a>
              </li>
              <li>
                <a href="/requests" className="footer-nav-link" onClick={(e) => handleNav(e, '/requests')}>
                  Requests
                </a>
              </li>
              <li>
                <a href="/about" className="footer-nav-link" onClick={(e) => handleNav(e, '/about')}>
                  About
                </a>
              </li>
              <li>
                <a href="/help" className="footer-nav-link" onClick={(e) => handleNav(e, '/help')}>
                  Help
                </a>
              </li>
              <li>
                <a href="/contact" className="footer-nav-link" onClick={(e) => handleNav(e, '/contact')}>
                  Contact
                </a>
              </li>
            </ul>
          </nav>

          {/* Right: Legal/Info */}
          <div className="footer-legal">
            <p>RGPV Affiliated College Project</p>
            <p>Minor Project-I</p>
          </div>
        </div>

        <div className="footer-copyright">
          <p>&copy; 2026 U-NOTE &middot; Built for RGPV Students</p>
        </div>
      </div>
    </footer>
  )
}

export default Footer
