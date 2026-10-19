import { useState } from 'react'

function AuthPages({ mode = 'login', onNavigate, onLoginSuccess }) {
  const isLogin = mode === 'login'
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    branch: '',
    semester: '1'
  })

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    // Simulate user login for demo / UI testing
    onLoginSuccess({
      name: formData.name || (formData.email.split('@')[0] || 'RGPV Student'),
      email: formData.email,
      branch: formData.branch || 'AIML',
      semester: formData.semester || 4
    })
    onNavigate('/')
  }

  const handleDemoSignIn = () => {
    onLoginSuccess({
      name: 'Aman Patel',
      email: 'aman.patel@rgpv.ac.in',
      branch: 'CSE',
      semester: 4
    })
    onNavigate('/')
  }

  return (
    <div className="auth-page-container">
      <div className="section-container">
        <div className="auth-form-wrapper">
          <div className="auth-header">
            <h1 className="auth-title">
              {isLogin ? 'Log in to U-NOTE' : 'Create Student Account'}
            </h1>
            <p className="auth-subtitle">
              {isLogin
                ? 'Access your saved notes, upload history, and study requests.'
                : 'Join the community to find and share RGPV study resources.'}
            </p>
          </div>

          <div className="prototype-badge-box">
            <span className="prototype-badge-pill">UI Prototype</span>
            <p className="prototype-badge-text">
              Backend database authentication is in progress. You can use the Demo Sign In button below to test the profile navigation and user menu.
            </p>
          </div>

          <form className="auth-form" onSubmit={handleSubmit}>
            {!isLogin && (
              <div className="form-group">
                <label htmlFor="name">Full Name</label>
                <input
                  type="text"
                  id="name"
                  name="name"
                  className="form-control"
                  placeholder="e.g. Aman Patel"
                  value={formData.name}
                  onChange={handleChange}
                  required
                />
              </div>
            )}

            <div className="form-group">
              <label htmlFor="email">Email Address</label>
              <input
                type="email"
                id="email"
                name="email"
                className="form-control"
                placeholder="student@college.edu or gmail"
                value={formData.email}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="password">Password</label>
              <input
                type="password"
                id="password"
                name="password"
                className="form-control"
                placeholder="Enter password"
                value={formData.password}
                onChange={handleChange}
                required
              />
            </div>

            {!isLogin && (
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="branch">Branch</label>
                  <select
                    id="branch"
                    name="branch"
                    className="form-control"
                    value={formData.branch}
                    onChange={handleChange}
                    required
                  >
                    <option value="" disabled>Select branch</option>
                    <option value="AIML">AIML</option>
                    <option value="CSE">CSE</option>
                    <option value="IT">IT</option>
                    <option value="EC">EC</option>
                    <option value="ME">ME</option>
                    <option value="Civil">Civil</option>
                  </select>
                </div>

                <div className="form-group">
                  <label htmlFor="semester">Semester</label>
                  <select
                    id="semester"
                    name="semester"
                    className="form-control"
                    value={formData.semester}
                    onChange={handleChange}
                    required
                  >
                    {[1, 2, 3, 4, 5, 6, 7, 8].map((sem) => (
                      <option key={sem} value={sem}>
                        Semester {sem}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            )}

            <div className="auth-actions">
              <button type="submit" className="btn btn-primary auth-submit-btn">
                {isLogin ? 'Log In' : 'Create Account'}
              </button>

              <button
                type="button"
                className="btn btn-secondary demo-login-btn"
                onClick={handleDemoSignIn}
              >
                Sign In with Demo Student Profile
              </button>
            </div>
          </form>

          <div className="auth-switch-footer">
            {isLogin ? (
              <p>
                Don't have an account yet?{' '}
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => onNavigate('/signup')}
                >
                  Sign Up
                </button>
              </p>
            ) : (
              <p>
                Already have an account?{' '}
                <button
                  type="button"
                  className="text-link-btn"
                  onClick={() => onNavigate('/login')}
                >
                  Log In
                </button>
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default AuthPages
