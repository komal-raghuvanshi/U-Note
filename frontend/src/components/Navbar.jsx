import { useState, useRef, useEffect } from 'react'

function Navbar({ onNavigate, currentPath = '/', user, onOpenProfile, onLogout }) {
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const dropdownRef = useRef(null)

  // Close dropdown on outside click
  useEffect(() => {
    const handleOutsideClick = (event) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
        setDropdownOpen(false)
      }
    }
    document.addEventListener('mousedown', handleOutsideClick)
    return () => document.removeEventListener('mousedown', handleOutsideClick)
  }, [])

  const handleLinkClick = (e, path, sectionId = null) => {
    e.preventDefault()
    setDropdownOpen(false)
    setMobileOpen(false)
    if (onNavigate) {
      onNavigate(path, sectionId)
    }
  }

  return (
    <header className="navbar">
      <div className="nav-container">
        <a
          href="/"
          className="nav-logo"
          onClick={(e) => handleLinkClick(e, '/')}
        >
          U-NOTE
        </a>

        <button
          type="button"
          className="nav-hamburger"
          onClick={() => setMobileOpen((prev) => !prev)}
          aria-label="Toggle navigation menu"
          aria-expanded={mobileOpen}
        >
          ☰
        </button>

        <nav className={`nav-links${mobileOpen ? ' nav-links-open' : ''}`}>
          <a
            href="/"
            className={`nav-link ${currentPath === '/' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/')}
          >
            Home
          </a>
          <a
            href="/about"
            className={`nav-link ${currentPath === '/about' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/about')}
          >
            About
          </a>
          <a
            href="/resources"
            className={`nav-link ${currentPath === '/resources' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/resources')}
          >
            Resources
          </a>
          <a
            href="/help"
            className={`nav-link ${currentPath === '/help' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/help')}
          >
            Help
          </a>
          <a
            href="/contact"
            className={`nav-link ${currentPath === '/contact' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/contact')}
          >
            Contact Us
          </a>
        </nav>

        <div className="nav-actions">
          {user ? (
            <div className="user-menu-wrapper" ref={dropdownRef}>
              <button
                type="button"
                className="nav-avatar-btn"
                onClick={() => setDropdownOpen((prev) => !prev)}
                aria-expanded={dropdownOpen}
                aria-label="User Profile Menu"
                title={user.name}
              >
                {user.avatar ? (
                  <img src={user.avatar} alt={user.name} className="nav-avatar-img" />
                ) : (
                  <span className="nav-avatar-fallback">
                    {user.name.charAt(0).toUpperCase()}
                  </span>
                )}
              </button>

              {dropdownOpen && (
                <div className="user-dropdown-menu">
                  <div className="dropdown-user-info">
                    <strong>{user.name}</strong>
                    <span>{user.email}</span>
                  </div>
                  <div className="dropdown-divider"></div>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => {
                      setDropdownOpen(false)
                      onOpenProfile('profile')
                    }}
                  >
                    My Profile
                  </button>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => {
                      setDropdownOpen(false)
                      onOpenProfile('shared')
                    }}
                  >
                    My Shared Resources
                  </button>
                  <button
                    type="button"
                    className="dropdown-item"
                    onClick={() => {
                      setDropdownOpen(false)
                      onOpenProfile('saved')
                    }}
                  >
                    Saved Resources
                  </button>
                  <div className="dropdown-divider"></div>
                  <button
                    type="button"
                    className="dropdown-item dropdown-logout-btn"
                    onClick={() => {
                      setDropdownOpen(false)
                      onLogout()
                    }}
                  >
                    Log Out
                  </button>
                </div>
              )}
            </div>
          ) : (
            <div className="auth-nav-buttons">
              <button
                type="button"
                className="btn btn-outline nav-auth-btn"
                onClick={() => onNavigate('/login')}
              >
                Login
              </button>
              <button
                type="button"
                className="btn btn-primary nav-auth-btn"
                onClick={() => onNavigate('/signup')}
              >
                Sign Up
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  )
}

export default Navbar
