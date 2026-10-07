function Navbar() {
  return (
    <header className="navbar">
      <div className="nav-container">
        <a href="#home" className="nav-logo">
          U-NOTE
        </a>
        <nav className="nav-links">
          <a href="#home" className="nav-link active">Home</a>
          <a href="#resources" className="nav-link">Resources</a>
          <a href="#about" className="nav-link">About</a>
        </nav>
        <div className="nav-actions">
          <button type="button" className="btn btn-outline">Login</button>
        </div>
      </div>
    </header>
  )
}

export default Navbar

