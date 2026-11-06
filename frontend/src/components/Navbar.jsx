import { useState, useRef, useEffect } from 'react'

function NavigationIcon({ name }) {
  const paths = {
    home: (
      <>
        <path d="m3 10 9-7 9 7" />
        <path d="M5 9v11h14V9M9 20v-6h6v6" />
      </>
    ),
    about: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M12 11v5M12 8h.01" />
      </>
    ),
    resources: (
      <>
        <path d="M3 5.5A2.5 2.5 0 0 1 5.5 3H12v17H5.5A2.5 2.5 0 0 0 3 22V5.5ZM21 5.5A2.5 2.5 0 0 0 18.5 3H12v17h6.5A2.5 2.5 0 0 1 21 22V5.5Z" />
      </>
    ),
    requests: (
      <>
        <rect x="5" y="4" width="14" height="17" rx="2" />
        <path d="M9 4.5V3h6v1.5M9 10h6M9 14h6M9 18h3" />
      </>
    ),
    help: (
      <>
        <circle cx="12" cy="12" r="9" />
        <path d="M9.8 9a2.3 2.3 0 1 1 3.8 1.7c-1 .9-1.6 1.3-1.6 2.8M12 16.5v.1" />
      </>
    ),
    contact: (
      <>
        <rect x="3" y="5" width="18" height="14" rx="2" />
        <path d="m4 7 8 6 8-6" />
      </>
    ),
  }

  return (
    <svg
      aria-hidden="true"
      className="nav-link-icon"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {paths[name]}
    </svg>
  )
}

function Navbar({ onNavigate, currentPath = '/', user, onOpenProfile, onLogout }) {
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const [avatarFailed, setAvatarFailed] = useState(false)
  const dropdownRef = useRef(null)
  const roleLabel = user?.role === 'teacher'
    ? 'Teacher'
    : user?.role === 'student' ? 'Student' : 'Member'

  useEffect(() => {
    setAvatarFailed(false)
  }, [user?.avatar])

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
          <img src="/favicon.png" alt="U-NOTE Logo" className="nav-logo-icon" />
          <span className="nav-logo-text">U-NOTE</span>
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
            <NavigationIcon name="home" />
            <span>Home</span>
          </a>
          <a
            href="/about"
            className={`nav-link ${currentPath === '/about' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/about')}
          >
            <NavigationIcon name="about" />
            <span>About</span>
          </a>
          <a
            href="/resources"
            className={`nav-link ${currentPath === '/resources' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/resources')}
          >
            <NavigationIcon name="resources" />
            <span>Resources</span>
          </a>
          <a
            href="/requests"
            className={`nav-link ${currentPath === '/requests' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/requests')}
          >
            <NavigationIcon name="requests" />
            <span>Requests</span>
          </a>
          <a
            href="/help"
            className={`nav-link ${currentPath === '/help' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/help')}
          >
            <NavigationIcon name="help" />
            <span>Help</span>
          </a>
          <a
            href="/contact"
            className={`nav-link ${currentPath === '/contact' ? 'active' : ''}`}
            onClick={(e) => handleLinkClick(e, '/contact')}
          >
            <NavigationIcon name="contact" />
            <span>Contact Us</span>
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
                {user.avatar && !avatarFailed ? (
                  <img
                    src={user.avatar}
                    alt={user.name}
                    className="nav-avatar-img"
                    onError={() => setAvatarFailed(true)}
                  />
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
                    <span className={`role-badge role-badge-${user.role || 'member'}`}>
                      {roleLabel}
                    </span>
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
